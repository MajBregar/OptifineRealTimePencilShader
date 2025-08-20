#version 430
#define GBUFFERS
#define VERTEX_SHADER
#include "lib/Inc.glsl"

in vec3 mc_Entity;

varying vec2 TexCoords;
varying vec4 Color;
varying vec3 ViewNormal;
varying vec2 Lightmap;

void main() {
    gl_Position = ftransform();

    ViewNormal = normalize(gl_NormalMatrix * gl_Normal);

    Lightmap = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    Lightmap = (Lightmap * 31.05 / 32.0) - (1.05 / 16.0);

    Color = gl_Color;
    
    TexCoords = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    

}
