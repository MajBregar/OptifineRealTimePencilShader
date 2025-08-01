#version 330
#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

varying vec2 TexCoords;
varying vec4 Color;

void main(){
    gl_Position = ftransform();
    gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);
    TexCoords = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    Color = gl_Color;
}

