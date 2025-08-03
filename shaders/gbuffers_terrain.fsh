#version 430
#define GBUFFERS
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"

varying vec2 TexCoords;
varying vec3 ModelPos;
varying vec3 ModelNormal;
varying vec2 Lightmap;
varying vec4 Color;
varying float Material;


void main(){
    vec4 default_color = texture2D(texture, TexCoords) * Color;

    /* RENDERTARGETS:0,1,2,3,10*/
    gl_FragData[0] = default_color;
    gl_FragData[1] = vec4(ModelNormal,      1.0);
    gl_FragData[2] = vec4(ModelPos,         1.0);
    gl_FragData[3] = vec4(Lightmap, 0.0, 1.0);
    gl_FragData[4] = vec4(Material, 0.0, 0.0, 1.0);
}