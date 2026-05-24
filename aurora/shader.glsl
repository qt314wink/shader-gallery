// Aurora Borealis — domain warping + fbm
// Jennipher Troup — Shader Gallery

precision mediump float;
uniform float u_time;
uniform vec2 u_res;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5); }

float noise(vec2 p) {
  vec2 i = floor(p), f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(
    mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
    mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
    f.y
  );
}

float fbm(vec2 p) {
  float v = 0.0, a = 0.5;
  for (int i = 0; i < 6; i++) { v += a * noise(p); p *= 2.0; a *= 0.5; }
  return v;
}

void main() {
  vec2 uv = (gl_FragCoord.xy / u_res) * 2.0 - 1.0;
  uv.x *= u_res.x / u_res.y;
  float t = u_time * 0.3;
  vec2 q = vec2(fbm(uv + t), fbm(uv + vec2(1.7, 9.2) + t * 0.8));
  float f = fbm(uv + 3.0 * q);
  vec3 col = mix(vec3(0.0, 0.02, 0.08),
    mix(vec3(0.1, 0.8, 0.4), vec3(0.0, 0.3, 0.9), f), f * 1.2);
  col = mix(col, vec3(0.8, 0.2, 0.9), clamp(f * f * 2.0 - 1.0, 0.0, 1.0));
  gl_FragColor = vec4(col, 1.0);
}
