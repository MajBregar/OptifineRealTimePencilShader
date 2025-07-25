#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"


varying vec2 TexCoords;
varying vec2 Lightmap;
varying vec3 ViewNormal;
varying vec3 WorldPos;
varying vec3 WorldNormal;
varying vec3 ModelPos;
varying vec3 ViewPos;

varying vec4 Color;

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
    vec4 c = texture2D(texture, TexCoords) * Color;
    vec2 blockUV = computeUV(ModelPos, WorldNormal);

    /* RENDERTARGETS:0,1,2,3,10,11 */
    gl_FragData[0] = c;
    gl_FragData[1] = vec4(WorldNormal, 1.0);
    gl_FragData[2] = vec4(Lightmap, 0.0, 1.0);
    gl_FragData[3] = vec4(blockUV, 0.0, 1.0);
    gl_FragData[4] = vec4(WorldPos, 1.0);
    gl_FragData[5] = vec4(ViewNormal, 1.0);
}