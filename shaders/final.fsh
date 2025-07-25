#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"

varying vec2 TexCoords;

void main() {
    vec3 c = texture2D(colortex0, TexCoords).rgb;
    gl_FragColor = vec4(c, 1.0);
}