#include <flutter/runtime_effect.glsl>

#ifdef GL_ES
precision highp float;
#endif

// Reveal mask for a gradient-sweep transition. Outputs alpha = how much of the
// "to" layer is visible (0 = none, 1 = all); the color channels are unused.

uniform vec2 u_resolution;
uniform float u_progress;      // 0..1
uniform float u_sweep_length;  // gradient height, in viewport heights
uniform float u_softness;      // 0 = linear ramp, 1 = fully eased
uniform float u_wobble;        // edge displacement, in viewport heights
uniform float u_wobble_scale;  // noise frequency of the wobble
uniform float u_grain;         // dither strength against banding
uniform float u_direction;     // 0 = top to bottom, 1 = bottom to top

out vec4 fragColor;

float hash21(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
             mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x),
             u.y);
}

// Two octaves, roughly -1..1; a pure function of position so scrubbing is repeatable.
float edge_noise(vec2 p) {
  float n = value_noise(p) * 0.65 + value_noise(p * 2.3 + 17.0) * 0.35;
  return n * 2.0 - 1.0;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_resolution.xy;
  if (u_direction > 0.5) uv.y = 1.0 - uv.y;
  float aspect = u_resolution.x / max(u_resolution.y, 1.0);
  float progress = clamp(u_progress, 0.0, 1.0);

  // Exact endpoints so the first and last frames are untouched.
  if (progress <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }
  if (progress >= 1.0) {
    fragColor = vec4(1.0);
    return;
  }

  float y = uv.y + edge_noise(vec2(uv.x * aspect, uv.y) * u_wobble_scale) * u_wobble;

  // Padded by the wobble so the sweep starts above and ends below the viewport.
  float edge = progress * (1.0 + u_sweep_length + 2.0 * u_wobble) - u_wobble;
  float blend = u_sweep_length > 0.0
      ? clamp((edge - y) / u_sweep_length, 0.0, 1.0)
      : step(y, edge);

  // Smootherstep so the ramp meets 0 and 1 with zero slope.
  float eased = blend * blend * blend * (blend * (blend * 6.0 - 15.0) + 10.0);
  blend = mix(blend, eased, clamp(u_softness, 0.0, 1.0));

  // Dither fades out where blend is 0 or 1 so untouched areas stay exact.
  float n = hash21(uv * vec2(1731.0, 1327.0)) - 0.5;
  blend = clamp(blend + n * u_grain * blend * (1.0 - blend) * 4.0, 0.0, 1.0);

  fragColor = vec4(blend);
}
