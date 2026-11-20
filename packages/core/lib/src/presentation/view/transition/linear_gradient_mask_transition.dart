import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:vector_math/vector_math.dart' as vm;

class LinearGradientMaskTransition extends StatefulWidget {
  final Animation<double> progress;
  final Widget? child;
  final FragmentProgram program;

  const LinearGradientMaskTransition({required this.progress, required this.program, this.child, super.key});

  @override
  State<LinearGradientMaskTransition> createState() => _LinearGradientMaskTransitionState();
}

class _LinearGradientMaskTransitionState extends State<LinearGradientMaskTransition> {
  // Own instance: ShaderMask reads uniforms at compositing time, so a shared
  // shader would pick up another transition's progress.
  late FragmentShader _shader = widget.program.fragmentShader();

  @override
  void didUpdateWidget(LinearGradientMaskTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program != widget.program) {
      _shader.dispose();
      _shader = widget.program.fragmentShader();
    }
  }

  @override
  void dispose() {
    _shader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.progress,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.xor,
        shaderCallback: (rect) {
          _shader.setFloatUniforms((setter) {
            setter.setVector(vm.Vector2(rect.width, rect.height));
            setter.setFloat(widget.progress.value);
          });
          return _shader;
        },
        child: child,
      ),
      child: widget.child,
    );
  }
}
