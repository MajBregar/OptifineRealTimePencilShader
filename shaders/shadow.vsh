#version 430
#define SHADOW
#define VERTEX_SHADER
#include "lib/Inc.glsl"


varying vec2 TexCoords;
varying vec4 Color;

void main(){
    TexCoords = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    Color = gl_Color;

    vec3 shadow_ndc = ftransform().rgb;
    vec3 distorted = distort_shadow_clip_pos(shadow_ndc);
    gl_Position = vec4(distorted, 1.0);
    

}

