#version 430
#define GBUFFERS
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"


varying vec2 TexCoords;
varying vec3 ModelPos;
varying vec3 ModelNormal;
varying vec4 Color;

varying vec2 UVs;


void main(){
    //vec4 c = texture2D(texture, TexCoords) * Color;
    
    /* RENDERTARGETS:1,9*/
    gl_FragData[0] = vec4(ModelNormal + HAND_NORMAL_OFFSET,      1.0);
    gl_FragData[1] = vec4(UVs, 0.0, 1.0);

}