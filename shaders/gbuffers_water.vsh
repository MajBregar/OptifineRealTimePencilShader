#version 430
#define GBUFFERS
#define VERTEX_SHADER
#include "lib/Inc.glsl"

in vec3 mc_Entity;

varying vec2 TexCoords;
varying vec2 Lightmap;
varying vec4 Color;
varying float Material;

varying vec3 ViewNormal;
varying vec2 UVs;

void main() {
    gl_Position = ftransform();
    TexCoords = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    ViewNormal = normalize(gl_NormalMatrix * gl_Normal);

    Lightmap = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    Lightmap = Lightmap / (30.0 / 32.0) - (1.0 / 32.0);
    
    Color = gl_Color;

    Material = mc_Entity.x;

    int vid = (gl_VertexID % 4);
    UVs = vec2(vid == 1 || vid == 2 ? 1 : 0, vid >> 1);

}
