#version 430
#define COMPOSITE
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"

varying vec2 TexCoords;

const vec3 tint = (vec3(float(240), float(213), float(185)) / 256) * 1.0;


void main() {

    int material = get_id(TexCoords);
    vec2 face_uv = texture2D(TANGENT_SPACE_UVS, TexCoords).xy;  
    vec2 lightmap = texture2D(LIGHTMAP, TexCoords).rg;
    vec3 view_normal = texture2D(VIEW_NORMALS, TexCoords).rgb;
    float raw_depth = texture2D(DEPTH_BUFFER_ALL, TexCoords).r;
    vec3 mip_levels = read_mip_level(TexCoords);
    vec3 default_albedo = texture2D(ALBEDO_BUFFER, TexCoords).rgb;


    float lighting_color = process_lighting(TexCoords, face_uv, view_normal, lightmap, raw_depth, material);
    float contour_color = get_displaced_fragment_contour_color(TexCoords, face_uv, mip_levels);
    vec3 paper_texture = sample_grayscale_mip_interpolated(PAPER_TEXTURE, face_uv, TexCoords);


    float contrast_adjustment = get_contrast_adjustment();

    //SKY SHADING
    if (material == SKY){
        float sky_blend = pencil_blend_function(min(lighting_color, contour_color), contour_color, 1.0, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
        vec3 sky_shading_color = vec3(clamp(sky_blend - contrast_adjustment, 0.0, 1.0));

        vec3 final_color = (ALBEDO_BLEND * default_albedo + (1.0 - ALBEDO_BLEND) * paper_texture) * sky_shading_color * tint;

        /* RENDERTARGETS:0 */
        gl_FragData[0] = vec4(final_color, 1.0);
        return;
    }

    //GEOMETRY SHADING
    float crosshatching_color = sample_pencil_shading(lighting_color, face_uv, TexCoords, mip_levels);
    float shading_blend = pencil_blend_function(min(crosshatching_color, contour_color), contour_color, 1.0, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    vec3 shading_color = vec3(clamp(shading_blend - contrast_adjustment, 0.0, 1.0));

    vec3 final_color = (ALBEDO_BLEND * default_albedo + (1.0 - ALBEDO_BLEND) * paper_texture) * shading_color * tint;

    /* RENDERTARGETS:0 */   
    gl_FragData[0] = vec4(final_color, 0.0);
}
