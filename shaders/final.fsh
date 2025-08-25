#version 430
#define FINAL
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"


varying vec2 TexCoords;

void main() {

    vec3 screen_color = texture2D(ALBEDO_BUFFER, TexCoords).rgb;

    vec2 uvs = texture2D(TANGENT_SPACE_UVS, TexCoords).rg;

    gl_FragColor = vec4(uvs, 0.0, 1.0);
}