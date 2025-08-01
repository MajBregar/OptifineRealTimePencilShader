#version 330
#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

varying vec2 TexCoords;
varying vec3 ModelPos;
varying vec3 ModelNormal;
varying vec2 Lightmap;
varying vec4 Color;

void main(){
    vec4 c = texture2D(texture, TexCoords) * Color;

    /* RENDERTARGETS:0,1,2,3*/
    gl_FragData[0] = c;
    gl_FragData[1] = vec4(ModelNormal,      1.0);
    gl_FragData[2] = vec4(ModelPos,         1.0);
    gl_FragData[3] = vec4(Lightmap,     0.0, 1.0);
}