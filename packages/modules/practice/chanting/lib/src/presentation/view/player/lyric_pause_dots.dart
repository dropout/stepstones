import 'dart:math' as math;

import 'package:chanting/src/domain/entity/lyrics_line_entity.dart';
import 'package:chanting/src/presentation/view/player/lyric_text_style.dart';
import 'package:chanting/src/presentation/view/player/lyric_word.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

/// Visual state of one pause dot at a moment in time.
class PauseDotFrame {
  const PauseDotFrame({required this.color, required this.scale});

  final Color color;
  final double scale;
}

/// Timing and look of the pause dots animation.
abstract final class PauseDots {
  static const int count = 3;
  static const double enlargedScale = 1.5;
  static const Duration outro = Duration(milliseconds: 750);
  static const Duration enlarge = Duration(milliseconds: 750);

  /// Overshoots past [enlargedScale] and settles back.
  static const Curve enlargeCurve = Curves.easeOutBack;

  /// Peak of [enlargeCurve] (easeOutBack tops out at ~1.087).
  static const double enlargeCurvePeak = 1.09;
  static const Duration pulseIn = Duration(milliseconds: 500);
  static const double pulsePeriodSeconds = 1.6;

  /// Extra scale at the peak of a pulse.
  static const double pulseAmount = 0.05;

  /// Radius and center spacing relative to the font size.
  static const double radiusFactor = 0.2;
  static const double spacingFactor = 0.75;

  /// Largest scale a dot reaches, used to reserve paint room.
  static const double maxScale = (1 + (enlargedScale - 1) * enlargeCurvePeak) * (1 + pulseAmount);

  /// Computes every dot's frame for [position] within [line].
  ///
  /// The fill time is split into equal thirds; each dot turns gold during its
  /// third, then enlarges. The tail of the line shrinks the dots back to the
  /// sung look. Short lines shrink the outro and enlarge windows proportionally.
  static List<PauseDotFrame> frames({
    required LyricsLineEntity line,
    required Duration position,
    required double pulseTime,
    bool pulsing = true,
  }) {
    final total = _seconds(line.end - line.start);
    final t = _seconds(position - line.start);
    if (total <= 0 || t < 0) return _still(LyricWordWidget.colorOf(.pending));
    if (t >= total) return _still(LyricWordWidget.colorOf(.sung));

    final outroSpan = math.min(_seconds(outro), total * 0.35);
    final enlargeSpan = math.min(_seconds(enlarge), total * 0.2);
    final third = (total - outroSpan - enlargeSpan) / count;
    final fadeInSpan = math.min(_seconds(LyricWordWidget.fadeDuration), third);
    final pulseInSpan = math.min(_seconds(pulseIn), total * 0.1);

    final outroT = Curves.easeInOut.transform(_progress(t - (total - outroSpan), outroSpan));
    final base = Color.lerp(
      LyricWordWidget.colorOf(.pending),
      LyricWordWidget.colorOf(.active),
      _progress(t, fadeInSpan),
    )!;
    final envelope = pulsing ? math.min(_progress(t, pulseInSpan), 1 - outroT) : 0.0;
    final gold = LyricWordWidget.colorOf(.highlight);
    final sung = LyricWordWidget.colorOf(.sung);

    return List.generate(count, (i) {
      final fill = _progress(t - i * third, third);
      final grow = enlargeCurve.transform(_progress(t - (i + 1) * third, enlargeSpan));
      // Slight per-dot lag makes the pulse travel across the dots.
      final phase = 2 * math.pi * (pulseTime / pulsePeriodSeconds - i / 6);
      final pulse = pulseAmount * envelope * (1 - math.cos(phase)) / 2;
      return PauseDotFrame(
        color: Color.lerp(Color.lerp(base, gold, fill), sung, outroT)!,
        scale: (1 + (enlargedScale - 1) * grow * (1 - outroT)) * (1 + pulse),
      );
    });
  }

  static List<PauseDotFrame> _still(Color color) => List.filled(count, PauseDotFrame(color: color, scale: 1));

  static double _seconds(Duration d) => d.inMicroseconds / Duration.microsecondsPerSecond;

  /// Linear 0..1 progress through a span; zero-length spans count as done.
  static double _progress(double elapsed, double span) =>
      span <= 0 ? (elapsed >= 0 ? 1.0 : 0.0) : (elapsed / span).clamp(0.0, 1.0);
}

/// Renders a "..." pause line as three pulsing dots that fill one by one.
/// [placeholder] is laid out invisibly so the line keeps its measured height.
class LyricPauseDots extends StatefulWidget {
  const LyricPauseDots({
    super.key,
    required this.line,
    required this.position,
    required this.isAdvancing,
    required this.placeholder,
    this.speed = 1.0,
  });

  final LyricsLineEntity line;
  final Duration position;

  /// Whether playback is moving, so position can be extrapolated per frame.
  final bool isAdvancing;
  final double speed;
  final Widget placeholder;

  @override
  State<LyricPauseDots> createState() => _LyricPauseDotsState();
}

class _LyricPauseDotsState extends State<LyricPauseDots> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final ValueNotifier<int> _repaint = ValueNotifier(0);
  late Duration _anchorPosition = widget.position;
  late Duration _position = widget.position;
  Duration _anchorElapsed = Duration.zero;
  Duration _lastElapsed = Duration.zero;
  double _pulseTime = 0;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant LyricPauseDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    _anchorPosition = _position = widget.position;
    _anchorElapsed = _ticker.isActive ? _lastElapsed : Duration.zero;
    _syncTicker();
    _repaint.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  bool get _shouldRun => widget.isAdvancing && _position >= widget.line.start && _position < widget.line.end;

  void _syncTicker() {
    if (_shouldRun && !_ticker.isActive) {
      _anchorElapsed = _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (!_shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    _pulseTime += (elapsed - _lastElapsed).inMicroseconds / Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;
    // Position events arrive in steps, so advance it locally between rebuilds.
    _position = _anchorPosition + (elapsed - _anchorElapsed) * widget.speed;
    _repaint.value++;
    if (!_shouldRun) _ticker.stop();
  }

  @override
  Widget build(BuildContext context) {
    final style = LyricTextStyle.of(context);
    final fontSize = MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14.0);
    final pulsing = !MediaQuery.disableAnimationsOf(context);
    final radius = fontSize * PauseDots.radiusFactor;
    final spacing = fontSize * PauseDots.spacingFactor;
    final inset = radius * PauseDots.maxScale;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: widget.placeholder,
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: 2 * inset + (PauseDots.count - 1) * spacing,
            child: CustomPaint(
              painter: _PauseDotsPainter(
                repaint: _repaint,
                frames: () =>
                    PauseDots.frames(line: widget.line, position: _position, pulseTime: _pulseTime, pulsing: pulsing),
                radius: radius,
                spacing: spacing,
                inset: inset,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PauseDotsPainter extends CustomPainter {
  _PauseDotsPainter({
    required super.repaint,
    required this.frames,
    required this.radius,
    required this.spacing,
    required this.inset,
  });

  final List<PauseDotFrame> Function() frames;
  final double radius;
  final double spacing;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final current = frames();
    for (var i = 0; i < current.length; i++) {
      final frame = current[i];
      final center = Offset(inset + i * spacing, size.height / 2);
      canvas.drawCircle(center, radius * frame.scale, paint..color = frame.color);
    }
  }

  @override
  bool shouldRepaint(_PauseDotsPainter oldDelegate) => true;
}
