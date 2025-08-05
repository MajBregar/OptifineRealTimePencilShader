#version 430
#define GBUFFERS
#define VERTEX_SHADER
#include "lib/Inc.glsl"



varying vec2 TexCoords;
varying vec3 ModelPos;
varying vec3 ModelNormal;
varying vec4 Color;

varying vec2 Lightmap;
varying vec3 ViewNormal;


void main() {
    gl_Position = ftransform();
    TexCoords = gl_MultiTexCoord0.st;
    Color = gl_Color;

    Lightmap = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    Lightmap = (Lightmap * 31.05 / 32.0) - (1.05 / 16.0);

    ModelPos    = gl_Vertex.xyz;
    ModelNormal = normalize(gl_Normal);

    ViewNormal = normalize(gl_NormalMatrix * gl_Normal);
}

