#version 430
#define FINAL
#define VERTEX_SHADER
#include "lib/Inc.glsl"

varying vec2 TexCoords;

void main() {
   gl_Position = ftransform();
   TexCoords = gl_MultiTexCoord0.st;
}
