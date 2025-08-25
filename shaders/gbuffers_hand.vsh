#version 430
#define GBUFFERS
#define VERTEX_SHADER
#include "lib/Inc.glsl"



varying vec2 TexCoords;
varying vec4 Color;

varying vec2 Lightmap;
varying vec3 ViewNormal;


void main() {
    gl_Position = ftransform();

    TexCoords = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    Color = gl_Color;
    Lightmap = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    Lightmap = Lightmap / (30.0 / 32.0) - (1.0 / 32.0); 
    ViewNormal = normalize(gl_NormalMatrix * gl_Normal);


}

