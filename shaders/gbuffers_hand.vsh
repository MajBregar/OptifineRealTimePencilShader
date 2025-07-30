#version 120
#include "lib/Uniforms.glsl"
#include "lib/Common.glsl"


varying vec2 TexCoords;
varying vec3 ModelPos;
varying vec3 ModelNormal;
varying vec2 Lightmap;
varying vec4 Color;

void main() {
    gl_Position = ftransform();
    TexCoords = gl_MultiTexCoord0.st;

    ModelPos    = gl_Vertex.xyz;
    ModelNormal = normalize(gl_Normal);

    Color = gl_Color;
}
