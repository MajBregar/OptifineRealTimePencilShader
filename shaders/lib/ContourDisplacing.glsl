
vec2 get_displacement(vec2 uv, float layer) {
    vec2 dmap_sample_uv = vec2((uv.x + layer) / DISPLACEMENT_MAP_LAYER_COUNT, uv.y);
    vec2 encoded = texture2D(DISPLACEMENT_MAP, dmap_sample_uv).rg;
    return vec2((encoded.r - 0.5) * 2.0 * CONTOUR_SHAKE_MAX_DISPLACEMENT, (encoded.g - 0.5) * 2.0 * CONTOUR_SHAKE_MAX_DISPLACEMENT);
}

float get_displaced_fragment_contour_color(vec2 uv, vec2 face_uv){
    //the reason for this being in the frag shader instead of the compute shader with reverse logic is that i dont know how i would do thread write conflicts here
    //multiple threads blending to the same cell at once would cause race conditions unless i lock it while one is blending
    vec2 raw_displacement_1 = get_displacement(uv, 0.0);
    vec2 raw_displacement_2 = get_displacement(uv, 1.0);
    vec2 raw_displacement_3 = get_displacement(uv, 2.0);

    float contour_displacement_falloff_1 = 1.0 - pow(texture2D(SHADING_BUFFER_MAIN, clamp(uv + raw_displacement_1, 0.0, 1.0)).a, CONTOUR_DISPLACEMENT_FALLOFF);
    float contour_displacement_falloff_2 = 1.0 - pow(texture2D(SHADING_BUFFER_MAIN, clamp(uv + raw_displacement_2, 0.0, 1.0)).a, CONTOUR_DISPLACEMENT_FALLOFF);
    float contour_displacement_falloff_3 = 1.0 - pow(texture2D(SHADING_BUFFER_MAIN, clamp(uv + raw_displacement_3, 0.0, 1.0)).a, CONTOUR_DISPLACEMENT_FALLOFF);

    vec2 final_contour_displacement_1 = raw_displacement_1 * contour_displacement_falloff_1;
    vec2 final_contour_displacement_2 = raw_displacement_2 * contour_displacement_falloff_2;
    vec2 final_contour_displacement_3 = raw_displacement_3 * contour_displacement_falloff_3;

    float contour_1 = texture2D(SHADING_BUFFER_MAIN, clamp(uv + final_contour_displacement_1, 0.0, 1.0)).r;
    float contour_2 = texture2D(SHADING_BUFFER_MAIN, clamp(uv + final_contour_displacement_2, 0.0, 1.0)).r;
    float contour_3 = texture2D(SHADING_BUFFER_MAIN, clamp(uv + final_contour_displacement_3, 0.0, 1.0)).r;

    float noise = texture2D(noisetex, face_uv).r * CONTOUR_NOISE;

    float c1_blend = pencil_blend_function(1.0,      CONTOUR_CS, clamp(CONTOUR_UB * contour_1 - noise, 0.0, 1.0), CONTOUR_UW, CONTOUR_WP_THRESHOLD);
    float c2_blend = pencil_blend_function(c1_blend, CONTOUR_CS, clamp(CONTOUR_UB * contour_2 - noise, 0.0, 1.0), CONTOUR_UW, CONTOUR_WP_THRESHOLD);
    float c3_blend = pencil_blend_function(c2_blend, CONTOUR_CS, clamp(CONTOUR_UB * contour_3 - noise, 0.0, 1.0), CONTOUR_UW, CONTOUR_WP_THRESHOLD);

    return c3_blend;
}