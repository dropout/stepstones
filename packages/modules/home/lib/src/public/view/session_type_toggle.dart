import 'dart:async';
import 'dart:math' as math;

import 'package:chanting/l10n/chanting_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:core/core.dart';
import 'package:home/src/public/enum/home_screen_view_state.dart';
import 'package:material_ui/material_ui.dart';

/// Toggle button that switches the home screen between the timer settings view
/// and the chanting settings view. The widget uses callback pattern to notify
/// parent of mode changes.
class SessionTypeToggle extends StatelessWidget {
  final HomeScreenViewState activeMode;
  final ValueChanged<HomeScreenViewState>? onModeChanged;
  final EdgeInsetsGeometry? padding;

  const SessionTypeToggle({
    required this.activeMode,
    required this.onModeChanged,
    super.key,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (onModeChanged == null) {
      return _DisabledSessionTypeToggle(child: _builder(
        context, 
        activeMode,
        bgColor: Colors.grey.shade700,
        fgColor: Colors.grey.shade400,
      ));
    }

    return GestureDetector(
      onTap: () {
        HomeScreenViewState newMode =
            (activeMode == HomeScreenViewState.sitting)
            ? HomeScreenViewState.chanting
            : HomeScreenViewState.sitting;
        onModeChanged!(newMode);
        context.hapticsTap();
      },
      child: AnimatedSwitcher(
        duration: Durations.medium2,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _builder(context, activeMode),
      ),
    );
  }

  Widget _builder(BuildContext context, HomeScreenViewState item, {
    Color bgColor = AppColors.buttonBackground,
    Color fgColor = AppColors.buttonForeground,
  }) {
    return DecoratedBox(
      key: ValueKey(item.name),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: SizedBox.square(
        dimension: 60,
        child: Icon(
          (item == HomeScreenViewState.sitting)
              ? Icons.music_note
              : Icons.timer_outlined,
          size: 28,
          color: fgColor,
        ),
      ),
    );
  }
}

class _DisabledSessionTypeToggle extends StatefulWidget {
  const _DisabledSessionTypeToggle({required this.child});

  final Widget child;

  @override
  State<_DisabledSessionTypeToggle> createState() =>
      _DisabledSessionTypeToggleState();
}

class _DisabledSessionTypeToggleState
    extends State<_DisabledSessionTypeToggle> {
  final _tooltipKey = GlobalKey<TooltipState>();
  Timer? _timer;
  bool _visible = false;
  bool _dismissedOnThisTap = false;
  double _arrowX = 0;
  bool _tooltipBelow = true;

  Offset _positionTooltip(TooltipPositionContext context) {
    final position = positionDependentBox(
      size: context.overlaySize,
      childSize: context.tooltipSize,
      target: context.target,
      preferBelow: true,
      verticalOffset: context.targetSize.height / 2 + 4,
    );
    // The overlay clamps its position at screen edges, so the tip follows its target.
    _arrowX = context.target.dx - position.dx;
    _tooltipBelow = position.dy >= context.target.dy;
    return position;
  }

  void _dismiss(PointerEvent event) {
    if (event is PointerDownEvent) {
      _stopTracking();
    }
  }

  void _stopTracking() {
    _timer?.cancel();
    _timer = null;
    if (_visible) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_dismiss);
      _visible = false;
    }
  }

  void _onTap() {
    if (_dismissedOnThisTap) return;
    if (_tooltipKey.currentState!.ensureTooltipVisible()) {
      _visible = true;
      GestureBinding.instance.pointerRouter.addGlobalRoute(_dismiss);
      _timer = Timer(const Duration(seconds: 3), () {
        Tooltip.dismissAllToolTips();
        _stopTracking();
      });
      context.services.hapticsService.error();
    }
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      key: _tooltipKey,
      message: ChantingLocalizations.of(context).chantingSignInRequired,
      triggerMode: TooltipTriggerMode.manual,
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.only(
        left: DesignSpec.paddingMd,
        right: DesignSpec.paddingMd,
        top: DesignSpec.paddingLg,
        bottom: DesignSpec.paddingSm,
      ),
      decoration: ShapeDecoration(
        color: AppColors.backgroundPaperLight,
        shape: _SpeechBubbleBorder(
          arrowPosition: () => (_arrowX, _tooltipBelow),
          side: const BorderSide(color: AppColors.charcoal, width: 1.5),
        ),
      ),
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(),
      positionDelegate: _positionTooltip,
      child: Semantics(
        button: true,
        enabled: false,
        child: Listener(
          onPointerDown: (_) => _dismissedOnThisTap = _visible,
          child: GestureDetector(
            onTap: _onTap,
            // child: Opacity(opacity: 0.45, child: widget.child),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _SpeechBubbleBorder extends ShapeBorder {
  _SpeechBubbleBorder({
    required this.arrowPosition,
    this.side = BorderSide.none,
  }) : assert(side.strokeAlign == BorderSide.strokeAlignInside);

  final (double, bool) Function() arrowPosition;
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.all(side.style == BorderStyle.none ? 0 : side.width);

  @override
  ShapeBorder scale(double t) =>
      _SpeechBubbleBorder(arrowPosition: arrowPosition, side: side.scale(t));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final (arrowX, below) = arrowPosition();
    final inset = math.min(24.0, rect.width / 2);
    final x = rect.left + arrowX.clamp(inset, rect.width - inset);
    final body = below
        ? Rect.fromLTRB(rect.left, rect.top + 8, rect.right, rect.bottom)
        : Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom - 8);
    final edge = below ? body.top : body.bottom;
    final tip = below ? rect.top : rect.bottom;
    final bodyPath = Path()
      ..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(16)));
    final tipPath = Path()
      ..moveTo(x - 8, edge)
      ..lineTo(x, tip)
      ..lineTo(x + 8, edge)
      ..close();
    return Path.combine(PathOperation.union, bodyPath, tipPath);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    final path = getOuterPath(rect, textDirection: textDirection);
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(path, side.toPaint()..strokeWidth = side.width * 2);
    canvas.restore();
  }
}
