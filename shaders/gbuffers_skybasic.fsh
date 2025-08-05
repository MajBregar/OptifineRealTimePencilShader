#version 430
#define GBUFFERS
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"

void main(){

    vec2 sky_uv = get_skybox_uv(gl_FragCoord.xy);
    float sky_light = process_sky_lighting();

    /* RENDERTARGETS:3,9,10*/
    gl_FragData[0] = vec4(sky_light, 0.0, 0.0, 1.0);
    gl_FragData[1] = vec4(sky_uv, 0.0, 1.0);
    gl_FragData[2] = vec4(float(SKY), 0.0, 0.0, 1.0);
}