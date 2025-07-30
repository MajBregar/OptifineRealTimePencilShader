#version 120
#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

varying vec2 TexCoords;

void main() {
    vec3 c = texture2D(colortex8, TexCoords).rgb;
    gl_FragColor = vec4(c, 1.0);
}