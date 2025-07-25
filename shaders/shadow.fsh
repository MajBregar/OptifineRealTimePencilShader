
#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"

varying vec2 TexCoords;
varying vec4 Color;

void main() {
  vec4 color = texture2D(texture, TexCoords);
  if (color.a < 0.1) {
    discard;
  }
  gl_FragData[0] = color;
}
