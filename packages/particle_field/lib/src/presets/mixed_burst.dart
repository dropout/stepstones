import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../behaviors/behaviors.dart';
import '../behaviors/particle_behavior.dart';
import '../core/particle_buffers.dart';
import '../core/particle_system.dart';
import '../emitters/particle_template.dart';
import '../forces/forces.dart';
import '../render/atlas_factory.dart';
import '../render/particle_renderer.dart';

/// Physics and appearance applied to one particle kind in [MixedBurst].
class BurstConfiguration {
  const BurstConfiguration({
    this.color,
    this.palette = const [
      0xFFFF5252,
      0xFFFFD740,
      0xFF69F0AE,
      0xFF40C4FF,
      0xFFE040FB,
      0xFFFFFFFF,
    ],
    this.direction = -pi / 2,
    this.spread = 2 * pi,
    this.minSpeed = 40,
    this.maxSpeed = 80,
    this.minLife = 1,
    this.maxLife = 3,
    this.minSize = 1,
    this.maxSize = 1,
    this.gravityX = 0,
    this.gravityY = 32,
    this.dragCoefficient = 1.5,
    this.scaleStart = 1,
    this.scaleEnd = 0,
    this.fadeFrom = 1,
    this.fadeTo = 0,
  });

  /// Overrides [palette] with a single colour when set.
  final int? color;
  final List<int> palette;
  final double direction;
  final double spread;
  final double minSpeed;
  final double maxSpeed;
  final double minLife;
  final double maxLife;
  final double minSize;
  final double maxSize;
  final double gravityX;
  final double gravityY;
  final double dragCoefficient;
  final double scaleStart;
  final double scaleEnd;
  final double fadeFrom;
  final double fadeTo;
}

/// A burst preset that mixes shrinking circles and star sprites.
///
/// Circle and star particles have separate physics and lifecycle
/// configuration, but share one [system] and [renderer].
class MixedBurst {
  MixedBurst.withImage({
    required ui.Image starImage,
    Random? random,
    int maxParticles = 256,
    double radius = 6,
    double starSize = 16,
    bool rotateStars = true,
    BurstConfiguration regular = const BurstConfiguration(),
    BurstConfiguration stars = const BurstConfiguration(
      minSpeed: 28,
      maxSpeed: 64,
      minLife: 1.5,
      maxLife: 2.5,
      minSize: 0.7,
      maxSize: 1.2,
      gravityY: 72,
      dragCoefficient: 0.65,
    ),
  }) : this._(
         starImage,
         false,
         random: random,
         maxParticles: maxParticles,
         radius: radius,
         starSize: starSize,
         rotateStars: rotateStars,
         regular: regular,
         stars: stars,
       );

  MixedBurst._(
    this.starImage,
    this._ownsStarImage, {
    required Random? random,
    required int maxParticles,
    required this.radius,
    required this.starSize,
    required this.rotateStars,
    required BurstConfiguration regular,
    required BurstConfiguration stars,
  }) {
    _validateConfiguration(regular, 'regular');
    _validateConfiguration(stars, 'stars');
    _validateSystemArguments(maxParticles, radius, starSize);

    final regularMask = 1 << regularKind;
    final starMask = 1 << starKind;
    system = ParticleSystem(
      maxParticles: maxParticles,
      customChannels: 1,
      random: random,
      forces: [
        Drag(coefficient: regular.dragCoefficient, kindMask: regularMask),
        Gravity(
          x: regular.gravityX,
          y: regular.gravityY,
          kindMask: regularMask,
        ),
        Drag(coefficient: stars.dragCoefficient, kindMask: starMask),
        Gravity(x: stars.gravityX, y: stars.gravityY, kindMask: starMask),
      ],
      behaviors: [
        FadeOut(
          from: regular.fadeFrom,
          to: regular.fadeTo,
          kindMask: regularMask,
        ),
        _ScaleOverLifeFromInitial(
          start: regular.scaleStart,
          end: regular.scaleEnd,
          kindMask: regularMask,
        ),
        FadeOut(from: stars.fadeFrom, to: stars.fadeTo, kindMask: starMask),
        _ScaleOverLifeFromInitial(
          start: stars.scaleStart,
          end: stars.scaleEnd,
          kindMask: starMask,
        ),
      ],
    );

    _regularTemplate = _templateFor(regular, regularKind);
    _starTemplate = _templateFor(stars, starKind);
    renderer = _MixedBurstRenderer(
      starImage: starImage,
      radius: radius,
      starSize: starSize,
      rotateStars: rotateStars,
    );
  }

  static const regularKind = 0;
  static const starKind = 1;
  static const defaultStarAssetPath = 'packages/particle_field/assets/star.png';

  static Future<MixedBurst> load({
    Random? random,
    int maxParticles = 256,
    double radius = 6,
    double starSize = 16,
    bool rotateStars = true,
    BurstConfiguration regular = const BurstConfiguration(),
    BurstConfiguration stars = const BurstConfiguration(
      minSpeed: 28,
      maxSpeed: 64,
      minLife: 1.5,
      maxLife: 2.5,
      minSize: 0.7,
      maxSize: 1.2,
      gravityY: 72,
      dragCoefficient: 0.65,
    ),
    String starAssetPath = defaultStarAssetPath,
    AssetBundle? bundle,
  }) async {
    _validateConfiguration(regular, 'regular');
    _validateConfiguration(stars, 'stars');
    _validateSystemArguments(maxParticles, radius, starSize);
    final image = await loadAtlasImage(starAssetPath, bundle: bundle);
    return MixedBurst._(
      image,
      true,
      random: random,
      maxParticles: maxParticles,
      radius: radius,
      starSize: starSize,
      rotateStars: rotateStars,
      regular: regular,
      stars: stars,
    );
  }

  final ui.Image starImage;
  final double radius;
  final double starSize;
  final bool rotateStars;
  final bool _ownsStarImage;

  late final ParticleSystem system;
  late final ParticleRenderer renderer;
  late final ParticleTemplate _regularTemplate;
  late final ParticleTemplate _starTemplate;
  bool _disposed = false;

  /// Emits [count] shrinking circles at ([x], [y]) in particle space.
  void emit({int count = 1, double x = 0, double y = 0}) =>
      _emit(_regularTemplate, count, x, y);

  /// Emits [count] star sprites at ([x], [y]) in particle space.
  void emitStars({int count = 1, double x = 0, double y = 0}) =>
      _emit(_starTemplate, count, x, y);

  /// Emits one burst containing both particle kinds.
  void emitMixed({
    int regularCount = 32,
    int starCount = 8,
    double x = 0,
    double y = 0,
  }) {
    emit(count: regularCount, x: x, y: y);
    emitStars(count: starCount, x: x, y: y);
  }

  /// Removes all active particles.
  void clear() => system.clear();

  /// Disposes the star image when it was loaded by [MixedBurst.load].
  void dispose() {
    if (_ownsStarImage && !_disposed) {
      starImage.dispose();
    }
    _disposed = true;
  }

  void _emit(ParticleTemplate template, int count, double x, double y) {
    if (_disposed) {
      throw StateError('Cannot emit after MixedBurst.dispose()');
    }
    for (var i = 0; i < count; i++) {
      if (template.spawnAt(system, x, y) < 0) break;
    }
  }

  ParticleTemplate _templateFor(BurstConfiguration config, int kind) {
    final colors = _resolvePalette(config);
    return ParticleTemplate(
      spread: config.spread,
      direction: config.direction,
      minSpeed: config.minSpeed,
      maxSpeed: config.maxSpeed,
      minLife: config.minLife,
      maxLife: config.maxLife,
      minSize: config.minSize,
      maxSize: config.maxSize,
      colorPicker: (random) => colors[random.nextInt(colors.length)],
      kind: kind,
      onSpawn: (system, index) {
        system.buffers.custom[0][index] = system.buffers.size[index];
      },
    );
  }

  static List<int> _resolvePalette(BurstConfiguration config) {
    if (config.color != null) return [config.color!];
    return config.palette;
  }

  static void _validateConfiguration(BurstConfiguration config, String name) {
    if (config.color == null && config.palette.isEmpty) {
      throw ArgumentError.value(
        config.palette,
        '$name.palette',
        'Must not be empty',
      );
    }
    if (config.spread < 0 ||
        config.minSpeed < 0 ||
        config.maxSpeed < config.minSpeed ||
        config.minLife <= 0 ||
        config.maxLife < config.minLife ||
        config.minSize <= 0 ||
        config.maxSize < config.minSize ||
        config.dragCoefficient < 0 ||
        config.scaleStart < 0 ||
        config.scaleEnd < 0 ||
        config.fadeFrom < 0 ||
        config.fadeFrom > 1 ||
        config.fadeTo < 0 ||
        config.fadeTo > 1) {
      throw ArgumentError('$name has invalid particle ranges');
    }
  }

  static void _validateSystemArguments(
    int maxParticles,
    double radius,
    double starSize,
  ) {
    if (maxParticles <= 0) {
      throw ArgumentError.value(
        maxParticles,
        'maxParticles',
        'Must be positive',
      );
    }
    if (radius <= 0 || starSize <= 0) {
      throw ArgumentError('radius and starSize must be positive');
    }
  }
}

class _ScaleOverLifeFromInitial extends ParticleBehavior {
  const _ScaleOverLifeFromInitial({
    required this.start,
    required this.end,
    super.kindMask,
  });

  final double start;
  final double end;

  @override
  void update(ParticleBuffers b, int count, double dt, double time) {
    for (var i = 0; i < count; i++) {
      if (!affects(b.kind[i])) continue;
      final progress = b.life[i] <= 0
          ? 1.0
          : (b.age[i] / b.life[i]).clamp(0.0, 1.0);
      b.size[i] = b.custom[0][i] * (start + (end - start) * progress);
    }
  }
}

class _MixedBurstRenderer extends ParticleRenderer {
  const _MixedBurstRenderer({
    required this.starImage,
    required this.radius,
    required this.starSize,
    required this.rotateStars,
  });

  final ui.Image starImage;
  final double radius;
  final double starSize;
  final bool rotateStars;

  @override
  void paint(ui.Canvas canvas, ui.Size size, ParticleBuffers b) {
    final circlePaint = ui.Paint();
    final starPaint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
    final source = ui.Rect.fromLTWH(
      0,
      0,
      starImage.width.toDouble(),
      starImage.height.toDouble(),
    );

    for (var i = 0; i < b.count; i++) {
      if (b.kind[i] == MixedBurst.regularKind) {
        circlePaint.color = ui.Color(b.color[i]);
        canvas.drawCircle(
          ui.Offset(b.px[i], b.py[i]),
          radius * b.size[i],
          circlePaint,
        );
      } else if (b.kind[i] == MixedBurst.starKind) {
        final dimension = starSize * b.size[i];
        starPaint.colorFilter = ui.ColorFilter.mode(
          ui.Color(b.color[i]),
          ui.BlendMode.modulate,
        );
        canvas.save();
        canvas.translate(b.px[i], b.py[i]);
        if (rotateStars) canvas.rotate(b.rotation[i]);
        canvas.drawImageRect(
          starImage,
          source,
          ui.Rect.fromCenter(
            center: ui.Offset.zero,
            width: dimension,
            height: dimension,
          ),
          starPaint,
        );
        canvas.restore();
      }
    }
  }
}
