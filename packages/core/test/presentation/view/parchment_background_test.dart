import 'dart:ui';

import 'package:assets/assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parchment shader compiles and accepts its uniforms', () async {
    final program = await FragmentProgram.fromAsset(Assets.shaderParchment);
    final shader = program.fragmentShader();
    // u_size, u_display_size, u_scroll_offset, u_seed.
    for (var i = 0; i < 6; i++) {
      shader.setFloat(i, 1);
    }
    shader.dispose();
  });
}
