#version 430
#define SHADOW
#define VERTEX_SHADER
#include "../lib/Inc.glsl"


varying vec2 TexCoords;
varying vec4 Color;

void main(){
    gl_Position = ftransform();
    gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);
    TexCoords = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    Color = gl_Color;
}

