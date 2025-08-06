#version 430
#define COMPOSITE
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"

varying vec2 TexCoords;

void main() {

    int material = get_id(TexCoords);
    vec2 face_uv = texture2D(TANGENT_SPACE_UVS, TexCoords).xy;     
    float contour_color = get_displaced_fragment_contour_color(TexCoords, face_uv);
    float lighting_color = texture2D(colortex3, TexCoords).r;

    vec2 perceptual_brightness = vec2(eyeBrightnessSmooth) / 240.0;
    float perceptual_b_block = perceptual_brightness.x;
    float perceptual_b_sky = perceptual_brightness.y;
    float weight = clamp(1.0 - perceptual_b_sky, 0.0, 1.0);
    float adjusted_block = perceptual_b_block * weight;
    float contrast_adjustment = (adjusted_block + perceptual_b_sky) * 0.06;

    if (material == SKY){
        float final_sky_color = pencil_blend_function(min(contour_color, lighting_color), contour_color, CONTOUR_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

        vec3 output_color = vec3(clamp(final_sky_color - contrast_adjustment, 0.0, 1.0));

        /* RENDERTARGETS:4 */
        gl_FragData[0] = vec4(vec3(final_sky_color), 1.0);
        return;
    }

    //TEXTURING
    float shading_color = sample_pencil_shading(lighting_color, face_uv, TexCoords);
    float final_color = pencil_blend_function(min(contour_color, shading_color), contour_color, CONTOUR_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

    vec3 output_color = vec3(clamp(final_color - contrast_adjustment, 0.0, 1.0));

    /* RENDERTARGETS:4 */   
    gl_FragData[0] = vec4(output_color, 1.0);
}
