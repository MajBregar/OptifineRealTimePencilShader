#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"


varying vec2 TexCoords;
varying vec3 ViewNormal;
varying vec2 Lightmap;
varying vec3 WorldPos;
varying vec3 WorldNormal;
varying vec3 ModelPos;
varying vec4 Color;

void main() {
    gl_Position = ftransform();

    TexCoords = gl_MultiTexCoord0.st;

    WorldPos = gl_Vertex.xyz;
    WorldNormal = normalize(gl_Normal);

    ModelPos = gl_Vertex.xyz - chunkOffset;

    Lightmap = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    Lightmap = (Lightmap * 31.05 / 32.0) - (1.05 / 16.0);

    ViewNormal = normalize(gl_NormalMatrix * gl_Normal);
    

    Color = gl_Color;
}
