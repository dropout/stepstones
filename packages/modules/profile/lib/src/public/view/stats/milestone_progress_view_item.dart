import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:particle_field/particle_field.dart' hide BoxShape;

enum MilestoneProgressViewItemMode { incomplete, completed, animate }

class MilestoneProgressViewItem extends StatefulWidget {
  final MilestoneProgressViewItemMode mode;
  final Color completedColor;
  final Color incompleteColor;

  /// Fires particle bursts in [MilestoneProgressViewItemMode.animate] mode.
  final bool celebrate;

  const MilestoneProgressViewItem({
    this.mode = MilestoneProgressViewItemMode.completed,
    this.celebrate = false,
    this.completedColor = Colors.green,
    this.incompleteColor = Colors.grey,
    super.key,
  });

  @override
  State<MilestoneProgressViewItem> createState() =>
      _MilestoneProgressViewItemState();
}

class _MilestoneProgressViewItemState extends State<MilestoneProgressViewItem>
    with TickerProviderStateMixin {
  // main animation controller
  late final AnimationController animationController;

  // circle and tick shape animations
  late final Animation<double> _circleAnimation;
  late final Animation<double> _shapeAnimation;

  // particle system
  MixedBurst? _achievementBurst;
  ParticleController? _particleController;
  bool _isLoadingBurst = false;

  // A static celebrating item swaps to the animated view once tapped.
  bool _isReplaying = false;
  final _random = Random();
  Timer? _animationTimer;
  Timer? _burstTimer;

  static const _burstCount = 3;
  static const _minBurstIntervalMs = 180;
  static const _burstIntervalVarianceMs = 181;

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.mode == MilestoneProgressViewItemMode.animate) {
      _scheduleAnimation();
    }

    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(.0, 1.0, curve: Curves.elasticOut),
      ),
    );

    _shapeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.5, 1.0),
      ),
    );

    super.initState();
  }

  bool get _isAnimateMode =>
      widget.mode == MilestoneProgressViewItemMode.animate;

  bool get _shouldCelebrate =>
      widget.celebrate && widget.mode != MilestoneProgressViewItemMode.incomplete;

  bool get _canReplay => _isAnimateMode || _shouldCelebrate;

  // Only a completed milestone needs the particle assets.
  Future<void> _loadAchievementBurst() async {
    if (_achievementBurst != null || _isLoadingBurst) return;
    _isLoadingBurst = true;
    final burst = await MixedBurst.load(
      random: _random,
      maxParticles: 512,      
      radius: 8.0,
      starSize: 18,      
      stars: BurstConfiguration(
        gravityY: 12.0,
        dragCoefficient: 3.0,
        minSpeed: 80,
        maxSpeed: 160,
        color: AppColors.appWhite.toARGB32(),
      ),
    );
    _isLoadingBurst = false;
    if (!mounted) {
      burst.dispose();
      return;
    }

    late final ParticleController controller;
    controller = ParticleController(
      vsync: this,
      system: burst.system,
      autoStart: false,
      onFrame: (system, _) {
        if (_burstTimer == null && system.count == 0) {
          controller.stop();
        }
      },
    );
    setState(() {
      _achievementBurst = burst;
      _particleController = controller;
    });
  }

  @override
  void didUpdateWidget(covariant MilestoneProgressViewItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode == widget.mode &&
        oldWidget.celebrate == widget.celebrate) {
      return;
    }

    _animationTimer?.cancel();
    _burstTimer?.cancel();
    _burstTimer = null;
    _particleController?.stop();
    _particleController?.clear();
    animationController.reset();
    _isReplaying = false;
    if (widget.mode == MilestoneProgressViewItemMode.animate) {
      _scheduleAnimation();
    }
  }

  void _scheduleAnimation() {
    if (_shouldCelebrate) _loadAchievementBurst();
    _animationTimer = Timer(const Duration(milliseconds: 256), _playAnimation);
  }

  void _playAnimation() {
    _animationTimer?.cancel();
    if (!_canReplay) return;
    if (!_isAnimateMode && !_isReplaying) {
      setState(() => _isReplaying = true);
    }
    animationController.forward(from: 0.0);
    _particleController?.clear();
    if (_shouldCelebrate) {
      _loadAchievementBurst();
      _startBursts();
    }
  }

  // Emits three bursts with random gaps between them.
  void _startBursts([int remaining = _burstCount]) {
    _burstTimer?.cancel();
    if (remaining == 0 || !mounted || !_shouldCelebrate) {
      _burstTimer = null;
      return;
    }
    if (_achievementBurst == null || _particleController == null) {
      _burstTimer = Timer(
        const Duration(milliseconds: 50),
        () => _startBursts(remaining),
      );
      return;
    }

    final x = (_random.nextDouble() - 0.5) * 12;
    final y = (_random.nextDouble() - 0.5) * 12;
    _achievementBurst!.emitStars(x: x, y: y, count: 6);    
    _particleController!.start();

    if (remaining == 1) {
      _burstTimer = null;
      return;
    }
    final delay =
        _minBurstIntervalMs + _random.nextInt(_burstIntervalVarianceMs);
    _burstTimer = Timer(
      Duration(milliseconds: delay),
      () => _startBursts(remaining - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Other items stay static and cheap.
        if (_canReplay) _playAnimation();
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (widget.mode) {
      case MilestoneProgressViewItemMode.incomplete:
        return _buildIncomplete();
      case MilestoneProgressViewItemMode.completed:
        return _isReplaying ? _buildAnimated() : _buildCompleted();
      case MilestoneProgressViewItemMode.animate:
        return _buildAnimated();
    }
  }

  Widget _buildIncomplete() {
    return DecoratedBox(
      key: const Key('milestone_progress_view_item_incomplete'),
      decoration: BoxDecoration(
        color: widget.incompleteColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Color.lerp(widget.incompleteColor, Colors.white, 0.2)!,
          width: 2.0,
        ),
      ),
    );
  }

  Widget _buildCompleted() {
    return DecoratedBox(
      key: const Key('milestone_progress_view_item_completed'),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Color.lerp(widget.completedColor, Colors.white, 0.2)!,
          width: 2.0,
        ),
        gradient: RadialGradient(
          colors: [
            Color.lerp(widget.completedColor, Colors.black, 0.15)!,
            widget.completedColor,
          ],
          stops: const [0.33, 1.0],
        ),
      ),
      child: CustomPaint(painter: CheckShapePainter()),
    );
  }

  Widget _buildAnimated() {
    return Stack(
      key: const Key('milestone_progress_view_item_animated'),
      fit: StackFit.expand, // re-expand to fill the parent
      children: [
        _buildIncomplete(),
        if (_shouldCelebrate &&
            _particleController != null &&
            _achievementBurst != null)
          ParticleField(
            controller: _particleController!,
            renderer: _achievementBurst!.renderer,
            clip: false,
          ),
        AnimatedBuilder(
          animation: _circleAnimation,
          builder: (BuildContext context, Widget? child) {
            return CustomPaint(
              painter: CirclePainter(
                color: widget.completedColor,
                animation: _circleAnimation.value,
              ),
              foregroundPainter: CheckShapePainter(
                color: Colors.white,
                animation: _shapeAnimation.value,
              ),
              child: child,
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _burstTimer?.cancel();
    animationController.dispose();
    _particleController?.dispose();
    _achievementBurst?.dispose();
    super.dispose();
  }
}

class CirclePainter extends CustomPainter {
  final double animation;
  final Color color;

  CirclePainter({this.animation = 0.0, this.color = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final gradient = RadialGradient(
      colors: [Color.lerp(color, Colors.black, 0.15)!, color],
      stops: const [0.33, 1.0],
    );

    gradient.createShader(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ),
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 * animation,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CirclePainter oldDelegate) {
    return (oldDelegate.animation != animation || oldDelegate.color != color);
  }
}

class CheckShapePainter extends CustomPainter {
  // Center in 32x32 box
  static const List<double> checkShape = [9, 17, 13.5, 21.5, 23, 12];

  final Color color;
  final double animation;
  late final Paint p;

  CheckShapePainter({this.color = Colors.white, this.animation = 1.0}) {
    p = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Path path = createAnimatedPath(createCheckShapePath(size), animation);

    canvas.drawPath(path, p);
  }

  Path createCheckShapePath(Size size) {
    double xScaleRatio = size.width / 32;
    double yScaleRatio = size.height / 32;

    Path path = Path();
    path.moveTo(checkShape[0] * xScaleRatio, checkShape[1] * yScaleRatio);
    path.lineTo(checkShape[2] * xScaleRatio, checkShape[3] * yScaleRatio);
    path.lineTo(checkShape[4] * xScaleRatio, checkShape[5] * yScaleRatio);

    return path;
  }

  @override
  bool shouldRepaint(covariant CheckShapePainter oldDelegate) {
    return (oldDelegate.color != color || oldDelegate.animation != animation);
  }
}

Path createAnimatedPath(Path originalPath, double animationPercent) {
  // ComputeMetrics can only be iterated once!
  final totalLength = originalPath.computeMetrics().fold(
    0.0,
    (double prev, ui.PathMetric metric) => prev + metric.length,
  );
  final currentLength = totalLength * animationPercent;
  return extractPathUntilLength(originalPath, currentLength);
}

Path extractPathUntilLength(Path originalPath, double length) {
  var currentLength = 0.0;

  final path = Path();

  var metricsIterator = originalPath.computeMetrics().iterator;

  while (metricsIterator.moveNext()) {
    var metric = metricsIterator.current;

    var nextLength = currentLength + metric.length;

    final isLastSegment = nextLength > length;
    if (isLastSegment) {
      final remainingLength = length - currentLength;
      final pathSegment = metric.extractPath(0.0, remainingLength);

      path.addPath(pathSegment, Offset.zero);
      break;
    } else {
      // There might be a more efficient way of extracting an entire path
      final pathSegment = metric.extractPath(0.0, metric.length);
      path.addPath(pathSegment, Offset.zero);
    }

    currentLength = nextLength;
  }

  return path;
}
