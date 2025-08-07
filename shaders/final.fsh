#version 430
#define FINAL
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"


varying vec2 TexCoords;

void main() {

    vec3 default_albedo = texture2D(ALBEDO_BUFFER, TexCoords).rgb;
    vec3 tint = (vec3(float(240), float(213), float(185)) / 256) * 1.0;

    vec3 shading = texture2D(SHADING_BUFFER_MAIN, TexCoords).rgb;
    vec2 paper_sample_uv = texture2D(TANGENT_SPACE_UVS, TexCoords).xy;

    vec3 paper_texture = sample_mip_interpolated(PAPER_TEXTURE, paper_sample_uv, TexCoords);

    float texture_blend = 0.15;
    vec3 final_color = (texture_blend * default_albedo + (1.0 - texture_blend) * paper_texture) * shading * tint;

    gl_FragColor = vec4(final_color, 1.0);
}