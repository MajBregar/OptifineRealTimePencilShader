#version 430
#define SHADOW
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"


varying vec2 TexCoords;
varying vec4 Color;

void main() {
  vec4 color = texture2D(texture, TexCoords);
  if (color.a < 0.1) {
    discard;
  }
  gl_FragData[0] = color;
}
