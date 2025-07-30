#version 120
#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

varying vec2 TexCoords;
varying vec3 ModelPos;
varying vec3 ModelNormal;
varying vec4 Color;

void main(){
    //vec4 c = texture2D(texture, TexCoords) * Color;

    /* RENDERTARGETS:1*/
    gl_FragData[0] = vec4(ModelNormal + 10.0,      1.0);
}