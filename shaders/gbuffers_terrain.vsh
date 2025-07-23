#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"


varying vec2 TexCoords;
varying vec3 ViewNormal;
varying vec2 Lightmap;
varying vec3 WorldPos;
varying vec3 WorldNormal;

void main() {
    gl_Position = ftransform();

    TexCoords = gl_MultiTexCoord0.st;

    WorldPos = gl_Vertex.xyz - chunkOffset;
    WorldNormal = normalize(gl_Normal);

    Lightmap = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    Lightmap = (Lightmap * 31.05 / 32.0) - (1.05 / 16.0);

    ViewNormal = normalize(gl_NormalMatrix * gl_Normal);
}
