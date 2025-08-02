#version 330
#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"
#include "lib/BlockHandling.glsl"


varying vec2 TexCoords;

void main() {

    vec3 shading = texture2D(colortex4, TexCoords).rgb;
    
    vec3 model_pos = texture2D(colortex2, TexCoords).rgb;
    vec3 world_pos = model_pos + cameraPosition;

    vec3 world_normal = texture2D(colortex1, TexCoords).rgb;
    float depth_raw = texture2D(depthtex0, TexCoords).r;

    vec3 tint = vec3(float(219), float(187), float(149)) / 256;
    tint = tint * 1.2;

    if (depth_raw == 1.0){
        gl_FragColor = vec4(tint * shading, 1.0);
        return;
    }

    vec2 paper_sample_uv = world_normal.x > 1.0 ? texture2D(colortex8, TexCoords).xy : get_block_face_tangent_space_uv(world_pos, world_normal);
    vec3 paper_texture = texture2D(colortex7, paper_sample_uv).rgb;

    vec3 final_color = tint * paper_texture * shading;
    
    
    //vec3 test = texture2D(colortex10, TexCoords).rgb;

    gl_FragColor = vec4(final_color, 1.0);
}