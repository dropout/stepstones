import 'dart:ui';

import 'package:core/src/service/shader_service.dart';


class DefaultShaderService implements ShaderService {
  final Map<String, FragmentProgram> programs = {};
  final Map<String, FragmentShader> shaders = {};

  @override
  Future<FragmentShader> loadShader(String assetKey) async {
    if (shaders.containsKey(assetKey)) {
      return shaders[assetKey]!;
    }
    final program = await FragmentProgram.fromAsset(assetKey);
    final shader = program.fragmentShader();
    programs[assetKey] = program;
    shaders[assetKey] = shader;
    return shader;
  }

  @override
  FragmentShader shader(String assetKey) {
    if (shaders.containsKey(assetKey)) {
      return shaders[assetKey]!;
    } else {
      throw Exception('No shader found in cache with assetKey: $assetKey');
    }
  }

  @override
  FragmentProgram program(String assetKey) {
    if (programs.containsKey(assetKey)) {
      return programs[assetKey]!;
    } else {
      throw Exception('No shader program found in cache with assetKey: $assetKey');
    }
  }

  @override
  void close() {
    for (var shader in shaders.values) {
      shader.dispose();
    }
    shaders.clear();
    programs.clear();
  }
}
