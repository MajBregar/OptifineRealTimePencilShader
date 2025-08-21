#version 430
#define GBUFFERS
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"


varying vec2 TexCoords;
varying vec4 Color;
varying vec3 ViewNormal;
varying vec2 Lightmap;

void main(){
    vec4 default_color = texture2D(gtexture, TexCoords) * Color;

    float mat = entityId > 0 ? float(entityId) : float(MOBS_DEFAULT);
    vec2 adjusted_UVs = fract(TexCoords * get_entity_texture_multiplier(entityId));
    float mip_level = calculate_mip_level_depth(gl_FragCoord.z);

    /* RENDERTARGETS:0,1,2,9,8*/
    gl_FragData[0] = default_color;
    gl_FragData[1] = vec4(ViewNormal, 1.0);
    gl_FragData[2] = vec4(Lightmap, 0.0, 1.0);
    gl_FragData[3] = vec4(mat, 0.0, 0.0, 1.0);
    gl_FragData[4] = vec4(adjusted_UVs, mip_level, 1.0);

}

