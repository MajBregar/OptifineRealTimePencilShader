#version 120

#include "lib/Uniforms.inc"
#include "lib/Common.inc"

varying vec2 TexCoords;

#define DISPLACEMENT_MAP_LAYER_COUNT 3.0

vec2 decodeDisplacement(vec2 encoded) {
    return vec2(
        (encoded.r - 0.5) * 2.0 * CONTOUR_SHAKE_MAX_DISPLACEMENT,
        (encoded.g - 0.5) * 2.0 * CONTOUR_SHAKE_MAX_DISPLACEMENT
    );
}

void main() {
    vec2 dmap_uv1 = vec2(TexCoords.x / DISPLACEMENT_MAP_LAYER_COUNT, TexCoords.y);
    vec2 dmap_uv2 = dmap_uv1 + vec2(1.0 / DISPLACEMENT_MAP_LAYER_COUNT, 0.0);
    vec2 dmap_uv3 = dmap_uv1 + vec2(2.0 / DISPLACEMENT_MAP_LAYER_COUNT, 0.0);

    vec2 dr1 = decodeDisplacement(texture2D(colortex5, dmap_uv1).rg);
    vec2 dr2 = decodeDisplacement(texture2D(colortex5, dmap_uv2).rg);
    vec2 dr3 = decodeDisplacement(texture2D(colortex5, dmap_uv3).rg);
    vec2 uv1 = clamp(TexCoords + dr1, 0.0, 1.0);
    vec2 uv2 = clamp(TexCoords + dr2, 0.0, 1.0);
    vec2 uv3 = clamp(TexCoords + dr3, 0.0, 1.0);

    float c1_dropoff = pow(texture2D(colortex4, uv1).a, CONTOUR_DISPLACEMENT_FALLOFF);
    float c2_dropoff = pow(texture2D(colortex4, uv2).a, CONTOUR_DISPLACEMENT_FALLOFF);
    float c3_dropoff = pow(texture2D(colortex4, uv3).a, CONTOUR_DISPLACEMENT_FALLOFF);
    float elim_ind1 = c1_dropoff == 0.0 ? 0.0 : 1.0;
    float elim_ind2 = c2_dropoff == 0.0 ? 0.0 : 1.0;
    float elim_ind3 = c3_dropoff == 0.0 ? 0.0 : 1.0;


    vec2 disp1f = dr1 * c1_dropoff;
    vec2 disp2f = dr2 * c2_dropoff;
    vec2 disp3f = dr3 * c3_dropoff;
    vec2 uv1f = clamp(TexCoords + disp1f, 0.0, 1.0);
    vec2 uv2f = clamp(TexCoords + disp2f, 0.0, 1.0);
    vec2 uv3f = clamp(TexCoords + disp3f, 0.0, 1.0);

    // Sample contour texture at displaced locations
    float contour_1 = texture2D(colortex4, uv1f).r;
    float contour_2 = texture2D(colortex4, uv2f).r;
    float contour_3 = texture2D(colortex4, uv3f).r;

    vec2 noise_sample_uv = texture2D(colortex3, TexCoords).xy;
    float noise = texture2D(noisetex, noise_sample_uv).r * CONTOUR_NOISE;

    float c1_blend = pencil_blend_function(1.0,      CONTOUR_CS, clamp(CONTOUR_UB * contour_1 - noise, 0.0, 1.0) * elim_ind1, CONTOUR_UW, CONTOUR_WP_THRESHOLD);
    float c2_blend = pencil_blend_function(c1_blend, CONTOUR_CS, clamp(CONTOUR_UB * contour_2 - noise, 0.0, 1.0) * elim_ind2, CONTOUR_UW, CONTOUR_WP_THRESHOLD);
    float c3_blend = pencil_blend_function(c2_blend, CONTOUR_CS, clamp(CONTOUR_UB * contour_3 - noise, 0.0, 1.0) * elim_ind3, CONTOUR_UW, CONTOUR_WP_THRESHOLD);

    float final_color = c3_blend;


    /* RENDERTARGETS:7 */
    gl_FragData[0] = vec4(vec3(final_color), 1.0);
}
