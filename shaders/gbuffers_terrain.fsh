#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"


varying vec2 TexCoords;
varying vec2 Lightmap;
varying vec3 ViewNormal;
varying vec3 WorldPos;
varying vec3 WorldNormal;

vec2 computeUV(vec3 pos, vec3 normal) {
    vec3 blending = abs(normal);
    blending = normalize(max(blending, 0.0001));
    blending /= (blending.x + blending.y + blending.z);

    vec2 uvX = pos.zy;
    vec2 uvY = pos.xz;
    vec2 uvZ = pos.xy;

    return fract(
        uvX * blending.x +
        uvY * blending.y +
        uvZ * blending.z
    );
}


void main(){
    vec4 albedo = texture2D(texture, TexCoords);
    vec2 blockUV = computeUV(WorldPos, WorldNormal);
    vec3 view_normal_encoded = ViewNormal * 0.5 + 0.5;

    /* RENDERTARGETS:0,1,2,3 */
    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(view_normal_encoded, 1.0);
    gl_FragData[2] = vec4(Lightmap, 0.0, 1.0);
    gl_FragData[3] = vec4(blockUV, 0.0, 1.0);
}