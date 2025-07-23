#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"

void main(){
    gl_Position = ftransform();
}