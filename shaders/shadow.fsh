
#version 330
#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

varying vec2 TexCoords;
varying vec4 Color;

void main() {
  vec4 color = texture2D(texture, TexCoords);
  if (color.a < 0.1) {
    discard;
  }
  gl_FragData[0] = color;
}
