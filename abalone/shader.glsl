// Abalone — Iridescent Thin-Film Interference
// Jennipher Troup · Shader Gallery
//
// Technique: simulates the optical phenomenon of thin-film interference
// that gives abalone shell its shifting teal/pink/gold/violet iridescence.
// A base noise layer warps the surface normals; the view angle against
// those normals drives a hue rotation across a pearl-like palette.

precision mediump float;
uniform float u_time;
uniform vec2  u_res;

// --- Utilities -----------------------------------------------------------
float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(
    mix(hash(i),               hash(i + vec2(1.0, 0.0)), f.x),
    mix(hash(i + vec2(0.0,1.0)), hash(i + vec2(1.0, 1.0)), f.x),
    f.y
  );
}

float fbm(vec2 p) {
  float v = 0.0, a = 0.5;
  mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
  for (int i = 0; i < 6; i++) {
    v += a * noise(p);
    p  = rot * p * 2.1;
    a *= 0.48;
  }
  return v;
}

// Pearl / abalone palette — cycles through teal, gold, violet, pink
vec3 pearlPalette(float t) {
  vec3 a = vec3(0.55, 0.50, 0.55);
  vec3 b = vec3(0.45, 0.45, 0.45);
  vec3 c = vec3(1.00, 1.00, 1.00);
  vec3 d = vec3(0.00, 0.15, 0.40); // phase offsets → teal/violet/gold
  return a + b * cos(6.28318 * (c * t + d));
}

void main() {
  vec2 uv = (gl_FragCoord.xy / u_res) * 2.0 - 1.0;
  uv.x   *= u_res.x / u_res.y;

  float t = u_time * 0.18;

  // --- Layer 1: slow organic warp (the shell surface topology) ---
  vec2 warp1 = vec2(
    fbm(uv * 1.8 + vec2(t, t * 0.7)),
    fbm(uv * 1.8 + vec2(t * 0.6 + 4.3, -t * 0.5 + 1.7))
  );

  // --- Layer 2: finer warp on top (the thin-film micro-surface) ---
  vec2 warp2 = vec2(
    fbm(uv * 3.5 + warp1 * 1.4 + t * 0.5),
    fbm(uv * 3.5 + warp1 * 1.4 - t * 0.4 + 9.1)
  );

  // --- View-angle proxy: dot of warped normal with a slow-moving light ---
  vec3 normal = normalize(vec3(warp2 * 0.8, 1.0));
  vec3 light  = normalize(vec3(sin(t * 0.7) * 0.6, cos(t * 0.5) * 0.6, 1.0));
  float ndotl = dot(normal, light) * 0.5 + 0.5;

  // --- Thin-film hue: shifts with both view angle and position ---
  float filmPhase = fbm(uv * 2.0 + warp1 * 0.6) * 2.0
                  + ndotl * 1.6
                  + t * 0.25;

  vec3 col = pearlPalette(filmPhase);

  // --- Specular highlight: a sharp glint that drifts across the surface ---
  float spec = pow(max(0.0, dot(normal, light)), 32.0);
  col += vec3(1.0, 0.97, 0.92) * spec * 0.6;

  // --- Subtle dark base so shadow areas read as deep shell, not flat ---
  float depth = fbm(uv * 1.2 + t * 0.1);
  col = mix(col * 0.25, col, smoothstep(0.2, 0.7, depth));

  // --- Vignette ---
  float vig = 1.0 - dot(uv * 0.5, uv * 0.5);
  col *= smoothstep(0.0, 0.6, vig);

  gl_FragColor = vec4(col, 1.0);
}
