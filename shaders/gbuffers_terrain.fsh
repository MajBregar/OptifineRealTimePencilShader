#version 430
#define GBUFFERS
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"

varying vec2 TexCoords;
varying vec3 ModelPos;
varying vec3 ModelNormal;

varying vec3 ViewNormal;
varying vec2 Lightmap;
varying vec2 UVs;

varying vec4 Color;
varying float Material;


void main(){
    vec4 default_color = texture2D(texture, TexCoords) * Color;

    float mat = Material > 0.0 ? Material : float(BLOCKS_DEFAULT);
    
    vec3 frags = gl_FragCoord.xyz;

    float lighting = process_lighting(frags, UVs, ViewNormal, Lightmap);
    float mip_level = calculate_mip_level(frags, ViewNormal);

    /* RENDERTARGETS:0,1,2,3,10,9*/
    gl_FragData[0] = default_color;
    gl_FragData[1] = vec4(ModelNormal, 1.0);
    gl_FragData[2] = vec4(ModelPos, 1.0);
    gl_FragData[3] = vec4(lighting, 0.0, 0.0, 1.0);
    gl_FragData[4] = vec4(mat, 0.0, 0.0, 1.0);
    gl_FragData[5] = vec4(UVs, mip_level, 1.0);
}