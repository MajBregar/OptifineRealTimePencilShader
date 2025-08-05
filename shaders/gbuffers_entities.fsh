#version 430
#define GBUFFERS
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"


varying vec2 TexCoords;
varying vec3 ModelPos;
varying vec3 ModelNormal;
varying vec4 Color;

varying vec3 ViewNormal;
varying vec2 Lightmap;
varying vec2 UVs;

void main(){
    vec4 default_color = texture2D(texture, TexCoords) * Color;

    float mat = entityId > 0 ? float(entityId) : float(MOBS_DEFAULT);
    vec2 adjusted_UVs = fract(UVs * get_entity_texture_multiplier(entityId));

    float lighting = process_lighting(gl_FragCoord.xyz, UVs, ViewNormal, Lightmap);

    /* RENDERTARGETS:0,1,2,3,10,9*/
    gl_FragData[0] = default_color;
    gl_FragData[1] = vec4(ModelNormal, 1.0);
    gl_FragData[2] = vec4(ModelPos, 1.0);
    gl_FragData[3] = vec4(lighting, 0.0, 0.0, 1.0);
    gl_FragData[4] = vec4(mat, 0.0, 0.0, 1.0);
    gl_FragData[5] = vec4(adjusted_UVs, 0.0, 1.0);

}

