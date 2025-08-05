#version 430
#define GBUFFERS
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"


varying vec2 TexCoords;
varying vec3 ModelPos;
varying vec3 ModelNormal;
varying vec4 Color;

varying vec2 Lightmap;
varying vec3 ViewNormal;


void main(){
    vec4 default_color = texture2D(texture, TexCoords) * Color;
    
    float texture_sample_multiplier = 32.0;
    if (heldItemId == 30001){
        texture_sample_multiplier = 16.0;
    }

    float mat = heldItemId > 0 ? float(heldItemId) : float(IN_HAND_DEFAULT);
    vec2 UVs = fract(TexCoords * get_handheld_texture_multiplier(heldItemId));

    float lighting = process_lighting(gl_FragCoord.xyz, UVs, ViewNormal, Lightmap);

    /* RENDERTARGETS:0,1,2,3,10,9*/
    gl_FragData[0] = default_color;
    gl_FragData[1] = vec4(ModelNormal, 1.0);
    gl_FragData[2] = vec4(ModelPos, 1.0);
    gl_FragData[3] = vec4(lighting, 0.0, 0.0, 1.0);
    gl_FragData[4] = vec4(mat, 0.0, 0.0, 1.0);
    gl_FragData[5] = vec4(UVs, 0.0, 1.0);
}