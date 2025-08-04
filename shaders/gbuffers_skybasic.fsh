#version 430
#define GBUFFERS
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"

void main(){
    /* RENDERTARGETS:10*/
    gl_FragData[0] = vec4(1.0, 0.0, 0.0, 1.0);
}