#version 120

varying vec2 TexCoords;
varying vec2 Lightmap;
varying vec3 ViewNormal;
varying vec3 WorldPos;
varying vec3 WorldNormal;

uniform sampler2D texture;

vec2 computeUV(vec3 pos, vec3 normal) {
    vec3 n = abs(normal);
    vec2 uv;

    if (n.x > n.y && n.x > n.z) {
        // ±X face → use YZ plane
        uv = pos.zy;
    } else if (n.y > n.z) {
        // ±Y face → use XZ plane
        uv = pos.xz;
    } else {
        // ±Z face → use XY plane
        uv = pos.xy;
    }

    return fract(uv);
}


void main(){
    vec4 albedo = texture2D(texture, TexCoords);
    vec2 blockUV = computeUV(WorldPos, WorldNormal);

    /* RENDERTARGETS:0,1,10,11 */
    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(ViewNormal, 1.0);
    gl_FragData[2] = vec4(Lightmap, 0.0, 1.0);
    gl_FragData[3] = vec4(blockUV, 0.0, 1.0);
}