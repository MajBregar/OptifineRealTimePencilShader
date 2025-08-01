#version 120
#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

varying vec2 TexCoords;
varying vec3 ModelPos;
varying vec3 ModelNormal;
varying vec4 Color;

void main(){
    //vec4 c = texture2D(texture, TexCoords) * Color;
    

    vec3 view_pos = (gl_ModelViewMatrix * vec4(ModelPos, 1.0)).xyz;
    vec3 view_origin = (gl_ModelViewMatrix * vec4(vec3(0.0), 1.0)).xyz;
    vec3 view_normal = normalize(gl_NormalMatrix * ModelNormal);

    vec2 uv = get_model_tangent_uv(view_pos, view_origin, view_normal);


    /* RENDERTARGETS:1,2*/
    gl_FragData[0] = vec4(ModelNormal + 10.0,      1.0);
    gl_FragData[1] = vec4(uv, 0.0, 1.0);

}