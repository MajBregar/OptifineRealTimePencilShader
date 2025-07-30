#version 120

#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

varying vec2 TexCoords;

void main() {
    vec3 c = texture2D(colortex4, TexCoords).rgb;

    /* RENDERTARGETS:4 */
    gl_FragData[0] = vec4(c, 1.0);
}


