#version 430
#define GBUFFERS
#define VERTEX_SHADER
#include "lib/Inc.glsl"

varying vec2 TexCoords;
varying vec4 Color;


void main() {
    gl_Position = ftransform();
    TexCoords = gl_MultiTexCoord0.st;
    Color = gl_Color;
}
