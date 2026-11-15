// Image transition workbench. See plasma.frag for the lab uniform contract.
//
// Mirrors how Flutter transitions work: a transition is a function of a single
// `progress` in 0..1 (what an Animation<double> reports in AnimatedSwitcher,
// PageRouteBuilder.transitionsBuilder, FadeTransition, ...). 0 shows only the
// "from" image, 1 shows only the "to" image.
//
// Edit transition() below to experiment with other effects.

uniform Globals {
  vec4 time_res;
  vec4 mouse;
} u_globals;

uniform Params {
  vec4 p0;
  vec4 p1;
  vec4 p2;
  vec4 p3;
  vec4 p4;
  vec4 p5;
} u_params;

// First and second TextureParam in the experiment (from, to).
uniform sampler2D u_texture0;
uniform sampler2D u_texture1;

in vec2 v_uv;
out vec4 frag_color;

// Both source images are square (400x400): scale uv so the image covers the
// viewport instead of stretching, centered. Swap for plain `uv` if you want
// the stretch.
vec2 cover(vec2 uv, float aspect) {
  vec2 scale = aspect > 1.0 ? vec2(1.0, 1.0 / aspect) : vec2(aspect, 1.0);
  return (uv - 0.5) * scale + 0.5;
}

float hash21(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Smooth value noise, 0..1.
float value_noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
             mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x),
             u.y);
}

// Two octaves, roughly -1..1. A pure function of position, so scrubbing the
// progress back and forth is repeatable.
float edge_noise(vec2 p) {
  float n = value_noise(p) * 0.65 + value_noise(p * 2.3 + 17.0) * 0.35;
  return n * 2.0 - 1.0;
}

// ---------------------------------------------------------------------------
// `uv` is the viewport uv (0..1, origin top-left), `aspect` is width / height,
// and `progress` is 0..1. `sweep_length` is the gradient height in viewport
// heights; `softness` eases the ramp; `wobble` (viewport heights) displaces the
// sweep with noise of frequency `wobble_scale`; `grain` dithers the blend.
// ---------------------------------------------------------------------------
vec4 transition(vec2 uv, float aspect, float progress, float sweep_length,
                float softness, float wobble, float wobble_scale,
                float grain) {
  vec2 st = cover(uv, aspect);
  vec4 from = texture(u_texture0, st);
  vec4 to = texture(u_texture1, st);

  if (progress <= 0.0) return from;
  if (progress >= 1.0) return to;

  // Displace the row the sweep sees by up to +-wobble.
  float y = uv.y + edge_noise(vec2(uv.x * aspect, uv.y) * wobble_scale) * wobble;

  // The range is padded by the wobble on both ends, so the displaced sweep
  // starts fully above the image and ends fully below it.
  float edge = progress * (1.0 + sweep_length + 2.0 * wobble) - wobble;
  float blend = sweep_length > 0.0
      ? clamp((edge - y) / sweep_length, 0.0, 1.0)
      : step(y, edge);
  // Ease the ramp so it meets 0 and 1 with zero slope (no visible kink where
  // the sweep starts and ends). softness 0 = linear, 1 = fully eased.
  float eased = blend * blend * blend * (blend * (blend * 6.0 - 15.0) + 10.0);
  blend = mix(blend, eased, clamp(softness, 0.0, 1.0));

  // Per-pixel dither against banding, faded out where blend is 0 or 1 so the
  // untouched areas stay exact.
  float n = hash21(uv * vec2(1731.0, 1327.0)) - 0.5;
  blend = clamp(blend + n * grain * blend * (1.0 - blend) * 4.0, 0.0, 1.0);

  return mix(from, to, blend);
}

void main() {
  float time = u_globals.time_res.x;
  float aspect = u_globals.time_res.y / max(u_globals.time_res.z, 1.0);

  float progress = u_params.p0.x;
  float auto_play = u_params.p0.y;  // 1 = ignore slider, ping-pong over time
  float period = u_params.p0.z;     // seconds for one 0 -> 1 sweep
  float sweep_length = u_params.p0.w;
  float softness = u_params.p1.x;
  float wobble = u_params.p1.y;
  float wobble_scale = u_params.p1.z;
  float grain = u_params.p1.w;

  if (auto_play > 0.5) {
    float phase = fract(time / (2.0 * max(period, 0.01)));
    progress = 1.0 - abs(1.0 - 2.0 * phase);  // triangle wave 0 -> 1 -> 0
  }

  frag_color = transition(v_uv, aspect, clamp(progress, 0.0, 1.0), sweep_length,
                          softness, wobble, wobble_scale, grain);

  // Keep both samplers alive. The shader compiler drops uniforms that are never
  // read, and the lab then fails to bind the missing texture slot. This branch
  // never runs (the slider can't go below -1) but the compiler can't know that.
  if (u_params.p5.w < -1.0) {
    frag_color += texture(u_texture0, v_uv) + texture(u_texture1, v_uv);
  }
}
