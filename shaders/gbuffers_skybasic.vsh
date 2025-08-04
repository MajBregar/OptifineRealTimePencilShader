#version 430
#define GBUFFERS
#define VERTEX_SHADER
#include "lib/Inc.glsl"


void main() {
    gl_Position = ftransform();
}
