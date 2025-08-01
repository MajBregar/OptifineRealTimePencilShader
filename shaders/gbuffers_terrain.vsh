#version 330
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

    Lightmap = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    Lightmap = (Lightmap * 31.05 / 32.0) - (1.05 / 16.0);

    Color = gl_Color;
}
