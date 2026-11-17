#include <flutter/runtime_effect.glsl>

#ifdef GL_ES
precision highp float;
#endif

// Procedural parchment background, ported from parchment.frag (shader lab).
// Reproducible and scroll-aware: depends only on position, seed and scroll.
// Scroll is in viewport heights; the vignette is fixed to the screen.

uniform vec2 u_size;          // render surface size (downscaled)
uniform vec2 u_display_size;  // displayed size in logical pixels
uniform float u_scroll_offset;  // logical pixels
uniform float u_seed;

out vec4 fragColor;

// Look parameters, tuned in the lab.
const float parallax = 1.0;
const float aged = .75;
const float mottle_scale = 1.0;
const float grain_strength = 0.12;
const float vignette = 1.0;
const float grain_scale = 600.0;
const vec3 paper = vec3(0.953, 0.898, 0.671);  // #EFBF04
const vec3 dark = vec3(0.541, 0.353, 0.169);   // #8A5A2B

// Hash without sin(): stable across GPUs and cheap (Dave Hoskins' hash12).
float hash12(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash12(i);
  float b = hash12(i + vec2(1.0, 0.0));
  float c = hash12(i + vec2(0.0, 1.0));
  float d = hash12(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Rotation applied per octave so the noise lattice doesn't line up with the axes.
const mat2 kRot = mat2(0.8, 0.6, -0.6, 0.8);

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 v_uv = frag / u_size;
  float aspect = u_display_size.x / max(u_display_size.y, 1.0);

  // In viewport heights, so the look is independent of the render downscale.
  float scroll = u_scroll_offset / max(u_display_size.y, 1.0);
  float seed = u_seed;

  // The seed picks where in the (infinite) noise field this paper lives. Kept
  // below ~1000 so the hash stays precise in float32.
  vec2 offset = vec2(hash12(vec2(seed, 1.7)), hash12(vec2(seed, 9.3))) * 800.0;

  // Paper space: 1 unit = viewport height. Scrolling down moves the paper up.
  vec2 q = vec2(v_uv.x * aspect, v_uv.y);
  vec2 p = q + vec2(0.0, scroll * parallax) + offset;

  // Mottling: 3 octaves of low-frequency noise.
  vec2 m = kRot * p * mottle_scale;
  float mottling = vnoise(m) * 0.55 + vnoise(kRot * m * 2.3 + 17.0) * 0.3 +
                   vnoise(kRot * kRot * m * 5.1 + 41.0) * 0.15;

  // Aging blotches: soft clouds from low-frequency noise with a ragged finer
  // layer, thresholded over a wide range so edges feather out instead of
  // reading as shapes. The darker halo sits mid-transition.
  vec2 sp = kRot * p;
  float field = vnoise(sp * 1.1 + 53.0) * 0.75 + vnoise(sp * 4.7 + 29.0) * 0.25;
  float body = smoothstep(0.5, 0.85, field);
  float stain = body * 0.6 + 4.0 * body * (1.0 - body) * 0.4;

  // High-frequency grain in paper space, so it scrolls with the paper.
  float grain = vnoise(p * grain_scale) - 0.5;

  // Darker edges, fixed to the screen.
  vec2 e = (v_uv - 0.5) * vec2(aspect, 1.0);
  float edge = smoothstep(0.35, 0.95, length(e)) * vignette;

  float tone = (mottling - 0.5) * 0.55 * aged + 0.1 * aged + stain * 0.3 * aged +
               grain * grain_strength + edge;

  vec3 color = mix(paper, dark, clamp(tone, 0.0, 1.0));

  // Dither to hide banding in the smooth gradients.
  color += (hash12(floor(frag)) - 0.5) / 255.0;

  fragColor = vec4(color, 1.0);
}
