import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:vector_math/vector_math.dart' as vm;

enum GradientTransitionDirection { topToBottom, bottomToTop }

/// Reveals [child] over whatever is painted beneath it with a soft gradient
/// sweeping from top to bottom (or bottom to top, see [direction]), driven by [progress] (0 = hidden, 1 = shown).
///
/// [shader] is the program from `Assets.shaderGradientTransitionMask`.
/// Use it directly as a route transition, or with [GradientTransition.switcher]
/// to swap between two widgets.
class GradientTransition extends AnimatedWidget {
  final Animation<double> progress;
  final FragmentShader shader;
  final Widget? child;

  /// Gradient height in viewport heights.
  final double sweepLength;

  /// 0 = linear ramp, 1 = fully eased.
  final double softness;

  /// Noise displacement of the sweep, in viewport heights.
  final double wobble;

  /// Noise frequency of the wobble.
  final double wobbleScale;

  /// Dither strength against banding.
  final double grain;

  /// Which way the sweep travels.
  final GradientTransitionDirection direction;

  const GradientTransition({
    required this.progress,
    required this.shader,
    this.child,
    this.sweepLength = 0.6,
    this.softness = 1.0,
    this.wobble = 0.05,
    this.wobbleScale = 3.0,
    this.grain = 0.5,
    this.direction = GradientTransitionDirection.topToBottom,
    super.key,
  }) : super(listenable: progress);

  /// Stacks [from] below [to] and reveals [to] as [progress] goes 0 -> 1.
  static Widget switcher({
    required Animation<double> progress,
    required FragmentShader shader,
    required Widget from,
    required Widget to,
    double sweepLength = 0.6,
    double softness = 1.0,
    double wobble = 0.05,
    double wobbleScale = 3.0,
    double grain = 0.5,
    GradientTransitionDirection direction =
        GradientTransitionDirection.topToBottom,
    Key? key,
  }) {
    return Stack(
      key: key,
      fit: StackFit.passthrough,
      children: [
        from,
        GradientTransition(
          progress: progress,
          shader: shader,
          sweepLength: sweepLength,
          softness: softness,
          wobble: wobble,
          wobbleScale: wobbleScale,
          grain: grain,
          direction: direction,
          child: to,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = progress.value;

    // Always in the tree so the child keeps its state at the endpoints.
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        shader.setFloatUniforms((setter) {
          setter.setVector(vm.Vector2(rect.width, rect.height));
          setter.setFloat(value);
          setter.setFloat(sweepLength);
          setter.setFloat(softness);
          setter.setFloat(wobble);
          setter.setFloat(wobbleScale);
          setter.setFloat(grain);
          setter.setFloat(
            direction == GradientTransitionDirection.bottomToTop ? 1.0 : 0.0,
          );
        });
        return shader;
      },
      child: child,
    );
  }
}
