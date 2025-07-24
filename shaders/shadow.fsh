
#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"

varying vec2 TexCoords;
varying vec4 Color;

void main() {
    gl_FragData[0] = texture2D(texture, TexCoords) * Color;
}