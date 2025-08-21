#version 430
#define FINAL
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"


varying vec2 TexCoords;

void main() {

    vec3 screen_color = texture2D(ALBEDO_BUFFER, TexCoords).rgb;

    gl_FragColor = vec4(screen_color, 1.0);
}