#version 120

varying vec2 TexCoords;
varying vec3 ViewNormal;
varying vec2 Lightmap;
varying vec3 WorldPos;
varying vec3 WorldNormal;

uniform vec3 chunkOffset;

void main() {
    gl_Position = ftransform();

    TexCoords = gl_MultiTexCoord0.st;

    WorldPos = gl_Vertex.xyz - chunkOffset;
    WorldNormal = normalize(gl_Normal);

    Lightmap = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    Lightmap = (Lightmap * 33.05 / 32.0) - (1.05 / 32.0);

    ViewNormal = normalize(gl_NormalMatrix * gl_Normal);
}
