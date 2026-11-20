import 'dart:ui';

abstract interface class ShaderService {
  Future<FragmentShader> loadShader(String assetKey);

  /// Shared shader instance; only safe where uniforms are consumed at draw
  /// time (e.g. `CustomPainter`), not by `ShaderMask`.
  FragmentShader shader(String assetKey);

  /// Program for widgets that need their own [FragmentShader] instance.
  FragmentProgram program(String assetKey);

  void close();
}
