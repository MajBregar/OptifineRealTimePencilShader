#version 430
#define GBUFFERS
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"

varying vec2 TexCoords;
varying vec4 Color;

void main(){
    vec4 default_color = texture2D(gtexture, TexCoords) * Color;

    vec2 sky_uv = get_skybox_uv(gl_FragCoord.xy);

    /* RENDERTARGETS:8,9,0*/
    gl_FragData[0] = vec4(sky_uv, SKY_MIP_LEVEL, 1.0);
    gl_FragData[1] = vec4(float(SKY), 0.0, 0.0, 1.0);
    gl_FragData[2] = default_color;
}