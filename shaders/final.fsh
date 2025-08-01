#version 120
#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

varying vec2 TexCoords;

void main() {

    vec3 shading = texture2D(colortex4, TexCoords).rgb;
    
    vec3 model_pos = texture2D(colortex2, TexCoords).rgb;
    vec3 world_normal = texture2D(colortex1, TexCoords).rgb;
    float depth_raw = texture2D(depthtex0, TexCoords).r;

    vec3 tint = vec3(float(240), float(191), float(161)) / 256;


    if (depth_raw == 1.0){
        gl_FragColor = vec4(tint * shading, 1.0);
        return;
    }


    vec2 uv;
    if (world_normal.x > 1.0){
        uv = model_pos.xy;
    } else {
        vec3 world_pos = model_pos + cameraPosition;
        uv = get_model_tangent_uv(world_pos, vec3(0.0), world_normal);
    }

    vec3 paper_texture = texture2D(colortex7, uv).rgb;


    gl_FragColor = vec4(tint * paper_texture * shading, 1.0);
}