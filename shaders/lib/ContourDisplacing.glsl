
vec2 get_displacement(vec2 uv, float layer) {
    vec2 dmap_sample_uv = vec2((uv.x + layer) / DISPLACEMENT_MAP_LAYER_COUNT, uv.y);
    vec2 encoded = texture2D(DISPLACEMENT_MAP, dmap_sample_uv).rg;
    return (encoded - 0.5) * 2.0 * CONTOUR_SHAKE_MAX_DISPLACEMENT * vec2(1.0, aspectRatio);
}

float get_displaced_fragment_contour_color(vec2 screen_sample, vec2 face_uv){
    vec2 raw_displacement_1 = get_displacement(screen_sample, 0.0);
    vec2 raw_displacement_2 = get_displacement(screen_sample, 1.0);
    vec2 raw_displacement_3 = get_displacement(screen_sample, 2.0);

    
    float contour_displacement_falloff_1 = CONTOUR_DISPLACEMENT_FALLOFF > 0.0 ? 1.0 - pow(texture2D(SHADING_BUFFER_MAIN, clamp(screen_sample + raw_displacement_1, 0.0, 1.0)).g, CONTOUR_DISPLACEMENT_FALLOFF) : 1.0;
    float contour_displacement_falloff_2 = CONTOUR_DISPLACEMENT_FALLOFF > 0.0 ? 1.0 - pow(texture2D(SHADING_BUFFER_MAIN, clamp(screen_sample + raw_displacement_2, 0.0, 1.0)).g, CONTOUR_DISPLACEMENT_FALLOFF) : 1.0;
    float contour_displacement_falloff_3 = CONTOUR_DISPLACEMENT_FALLOFF > 0.0 ? 1.0 - pow(texture2D(SHADING_BUFFER_MAIN, clamp(screen_sample + raw_displacement_3, 0.0, 1.0)).g, CONTOUR_DISPLACEMENT_FALLOFF) : 1.0;

    vec2 final_contour_displacement_1 = raw_displacement_1 * contour_displacement_falloff_1;
    vec2 final_contour_displacement_2 = raw_displacement_2 * contour_displacement_falloff_2;
    vec2 final_contour_displacement_3 = raw_displacement_3 * contour_displacement_falloff_3;

    float contour_1 = texture2D(SHADING_BUFFER_MAIN, clamp(screen_sample + final_contour_displacement_1, 0.0, 1.0)).r;
    float contour_2 = texture2D(SHADING_BUFFER_MAIN, clamp(screen_sample + final_contour_displacement_2, 0.0, 1.0)).r;
    float contour_3 = texture2D(SHADING_BUFFER_MAIN, clamp(screen_sample + final_contour_displacement_3, 0.0, 1.0)).r;

    float c1_blend = pencil_blend_function(1.0,      (1.0 - contour_1), CONTOUR_UB, CONTOUR_UW, CONTOUR_WP_THRESHOLD);
    float c2_blend = pencil_blend_function(c1_blend, (1.0 - contour_2), CONTOUR_UB, CONTOUR_UW, CONTOUR_WP_THRESHOLD);
    float c3_blend = pencil_blend_function(c2_blend, (1.0 - contour_3), CONTOUR_UB, CONTOUR_UW, CONTOUR_WP_THRESHOLD);

    return c3_blend;
}