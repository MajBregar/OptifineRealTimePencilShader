

float sample_grid_mip_interpolated(vec2 tile_space_uv, int tile_id, vec3 mip_levels){
    vec2 main_mip_sample_uv = get_grid_mipmap_uv(tile_space_uv, tile_id, int(mip_levels.x + 0.5));
    vec2 higher_mip_sample_uv = get_grid_mipmap_uv(tile_space_uv, tile_id, int(mip_levels.y + 0.5));

    float grayscale_main =   texture2D(CROSSHATCHING_TEXTURE, main_mip_sample_uv).r;
    float grayscale_higher = texture2D(CROSSHATCHING_TEXTURE, higher_mip_sample_uv).r;

    return (1.0 - mip_levels.z) * grayscale_main + mip_levels.z * grayscale_higher;
}

float sample_pencil_shading(float light_level, vec2 tile_uv, vec2 screen_sample) {
    int tile_id = light_to_index(light_level);
    vec3 mip_levels = read_mip_level(screen_sample);

    float cs_horizontal =   sample_grid_mip_interpolated(tile_uv, tile_id, mip_levels);
    float cs_vertical =     sample_grid_mip_interpolated(fast_rotate_uv_90(tile_uv), tile_id, mip_levels);
    float cs_diagonal =     sample_grid_mip_interpolated(fast_rotate_uv_45(tile_uv), tile_id, mip_levels);

    float shading_blend_1 = pencil_blend_function(1.0,             cs_horizontal,   CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_2 = pencil_blend_function(shading_blend_1, cs_vertical,     CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_3 = pencil_blend_function(shading_blend_2, cs_diagonal,     CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

    return shading_blend_3;
}
