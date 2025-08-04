#version 430
#define GBUFFERS
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"

varying vec2 TexCoords;
varying vec4 Color;

void main(){
    vec4 default_color = texture2D(texture, TexCoords) * Color;
    
    /* RENDERTARGETS:9,10,0*/
    gl_FragData[0] = vec4(TexCoords, 0.0, 1.0);
    gl_FragData[1] = vec4(1.0, 0.0, 0.0, 1.0);
    gl_FragData[2] = default_color;
}