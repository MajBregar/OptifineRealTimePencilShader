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
    // Sample and decode each displacement map
    float fragment_depth_raw = texture2D(depthtex0, TexCoords).r;
    float fragment_depth = linearize_depth(fragment_depth_raw);   
    float depth_scale = 1.0 - clamp((fragment_depth - near) / (far - near), 0.0, 1.0);
    depth_scale = depth_scale * depth_scale;


    vec2 dmap_uv1 = vec2(TexCoords.x / DISPLACEMENT_MAP_LAYER_COUNT, TexCoords.y);
    vec2 dmap_uv2 = dmap_uv1 + vec2(1.0 / DISPLACEMENT_MAP_LAYER_COUNT, 0.0);
    vec2 dmap_uv3 = dmap_uv1 + vec2(2.0 / DISPLACEMENT_MAP_LAYER_COUNT, 0.0);

    vec2 disp1 = decodeDisplacement(texture2D(colortex5, dmap_uv1).rg) * depth_scale;
    vec2 disp2 = decodeDisplacement(texture2D(colortex5, dmap_uv2).rg) * depth_scale;
    vec2 disp3 = decodeDisplacement(texture2D(colortex5, dmap_uv3).rg) * depth_scale;

    // Displaced UVs
    vec2 uv1 = clamp(TexCoords + disp1, 0.0, 1.0);
    vec2 uv2 = clamp(TexCoords + disp2, 0.0, 1.0);
    vec2 uv3 = clamp(TexCoords + disp3, 0.0, 1.0);

    // Sample contour texture at displaced locations
    float contour_1 = 1.0 - texture2D(colortex7, uv1).r;
    float contour_2 = 1.0 - texture2D(colortex7, uv2).r;
    float contour_3 = 1.0 - texture2D(colortex7, uv3).r;

    float ca_1 = 1.0 * (1.0 - CONTOUR_CS);
    float ct_1 = 1.0 - CONTOUR_UB * ca_1 * contour_1;

    float ca_2 = ct_1 * (1.0 - CONTOUR_CS);
    float ct_2 = ct_1 - CONTOUR_UB * ca_2 * contour_2;

    float ca_3 = ct_2 * (1.0 - CONTOUR_CS);
    float ct_3 = ct_2 - CONTOUR_UB * ca_3 * contour_3;

    float final_color = ct_3;

    /* RENDERTARGETS:4 */
    gl_FragData[0] = vec4(vec3(final_color), 1.0);
}
