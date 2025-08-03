#version 430
#define FINAL
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"


varying vec2 TexCoords;

void main() {

    vec3 shading = texture2D(SHADING_BUFFER_MAIN, TexCoords).rgb;
    float depth_raw = texture2D(DEPTH_BUFFER_ALL, TexCoords).r;

    vec3 tint = (vec3(float(219), float(187), float(149)) / 256) * 1.2;

    if (depth_raw == 1.0){
        gl_FragColor = vec4(tint * shading, 1.0);
        return;
    }

    vec2 paper_sample_uv = texture2D(TANGENT_SPACE_UVS, TexCoords).xy;
    vec3 paper_texture = texture2D(PAPER_TEXTURE, paper_sample_uv).rgb;

    vec3 final_color = tint * paper_texture * shading;

    gl_FragColor = vec4(final_color, 1.0);
}