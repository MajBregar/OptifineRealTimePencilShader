

float sample_pencil_shading(float light_level, vec2 tile_uv, vec2 screen_sample) {
    int tile_id = light_to_index(light_level);

    if (tile_id == 0) return 1.0;

    vec3 mip_levels = read_mip_level(screen_sample);

    float cs_horizontal =   sample_grayscale_grid_mip_interpolated(tile_uv, tile_id, mip_levels);
    float cs_vertical =     sample_grayscale_grid_mip_interpolated(fast_rotate_uv_90(tile_uv), tile_id, mip_levels);
    float cs_diagonal =     sample_grayscale_grid_mip_interpolated(fast_rotate_uv_45(tile_uv), tile_id, mip_levels);

    float shading_blend_1 = pencil_blend_function(1.0,             cs_horizontal,   CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_2 = pencil_blend_function(shading_blend_1, cs_vertical,     CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_3 = pencil_blend_function(shading_blend_2, cs_diagonal,     CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

    vec3 mipped_normal = sample_mip_interpolated(NORMAL_MAP, tile_uv, screen_sample);
    vec3 normal_map = normalize(mipped_normal * 2.0 - 1.0);

    float final_color = shading_blend_3;
    final_color += shading_blend_3 < 0.99 ? light_level * NORMAL_MAP_COEF * dot(tangent_space_horizontal, normal_map) : 0.0;
    final_color += shading_blend_3 < 0.99 ? light_level * NORMAL_MAP_COEF * dot(tangent_space_vertical, normal_map) : 0.0;
    final_color += shading_blend_3 < 0.99 ? light_level * NORMAL_MAP_COEF * dot(tangent_space_45deg, normal_map) : 0.0;


    return final_color;
}
