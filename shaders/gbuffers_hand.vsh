#version 330

#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

in vec4 at_tangent;

varying vec2 TexCoords;
varying vec3 ModelPos;
varying vec3 ModelNormal;
varying vec2 Lightmap;
varying vec4 Color;

varying vec2 UVs;

void main() {
    gl_Position = ftransform();
    TexCoords = gl_MultiTexCoord0.st;
    Color = gl_Color;


    ModelPos    = gl_Vertex.xyz;
    ModelNormal = normalize(gl_Normal);

    vec3 ModelTangent = normalize(at_tangent.xyz);
    vec3 Bitangent = normalize(cross(ModelNormal, ModelTangent));
    UVs = vec2(dot(ModelPos, ModelTangent), dot(ModelPos, Bitangent));
}
