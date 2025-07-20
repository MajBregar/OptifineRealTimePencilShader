#version 120

varying vec2 TexCoords;
varying vec3 Normal;

// The texture atlas
uniform sampler2D texture;

void main(){
    // Sample from texture atlas and account for biome color + ambien occlusion
    vec4 albedo = texture2D(texture, TexCoords);
    /* DRAWBUFFERS:01 */
    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(normalize(Normal), 1.0f);
}