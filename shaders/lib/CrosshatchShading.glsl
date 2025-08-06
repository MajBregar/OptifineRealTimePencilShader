

vec2 index_to_tile_origin(float index) {
    float col = mod(index, GRID_SIZE);
    float row = floor(index / GRID_SIZE);
    return vec2(col, row) / GRID_SIZE;
}

vec2 mip_scalar_to_grid_origin(float mip_scalar){
    float grid_origin = 1.0 - mip_scalar;
    return vec2(grid_origin, 0.0);
}

vec2 sample_mipmap_layer_uv(vec2 tile_space_uv, int tile_index, int mip_level) {
    
    vec2 texture_aspect_ratio_inverse = vec2(0.5, 1.0);
    vec2 grid_tile_size_texture_uv = vec2(1.0 / GRID_SIZE, 1.0 / GRID_SIZE) * texture_aspect_ratio_inverse;

    vec2 tile_origin_in_grid_space = index_to_tile_origin(float(tile_index));

    int mip_devision = 1 << mip_level;
    float mip_scalar = 1.0 / mip_devision; //instead of pow(0.5, mip)

    vec2 tile_origin_in_grid_space_adjusted_for_mip = tile_origin_in_grid_space * mip_scalar;

    vec2 grid_origin_in_texture_space = mip_scalar_to_grid_origin(mip_scalar);

    vec2 tile_origin_in_texture_space = grid_origin_in_texture_space + tile_origin_in_grid_space_adjusted_for_mip * texture_aspect_ratio_inverse;

    vec2 tile_space_uv_scaled_for_texture_space = tile_space_uv * grid_tile_size_texture_uv * mip_scalar;

    vec2 texture_space_sample = tile_space_uv_scaled_for_texture_space + tile_origin_in_texture_space;

    return texture_space_sample;
}

int light_to_index(float light){
    return int((1.0 - light) * (TOTAL_TILES - 1.0));
}

int get_mip_level(vec2 screen_sample, int max_mip) {
    float mip_enc = texture2D(TANGENT_SPACE_UVS, screen_sample).b;
    mip_enc = mip_enc * MAX_MIP + 0.5;
    return int(mip_enc);
}

float sample_pencil_shading(float light_level, vec2 tile_uv, vec2 screen_sample) {

    int tile_id = light_to_index(light_level);
    int max_mip = 9;
    int mip_level = get_mip_level(screen_sample, max_mip);

    //horizontal sample
    vec2 side_sample_1 = sample_mipmap_layer_uv(tile_uv, tile_id, mip_level);         
    float cs_horizontal = texture2D(CROSSHATCHING_TEXTURE, side_sample_1).r;

    //vertical sample
    vec2 side_sample_2 = sample_mipmap_layer_uv(fast_rotate_uv_90(tile_uv), tile_id, mip_level);         
    float cs_vertical = texture2D(CROSSHATCHING_TEXTURE, side_sample_2).r;

    //diagonal sample
    vec2 diagonal_sample = sample_mipmap_layer_uv(fast_rotate_uv_45(tile_uv), tile_id, mip_level);
    float cs_diagonal = texture2D(CROSSHATCHING_TEXTURE, diagonal_sample).r;

    //combine
    float shading_blend_1 = pencil_blend_function(1.0,             cs_horizontal,   CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_2 = pencil_blend_function(shading_blend_1, cs_vertical,     CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_3 = pencil_blend_function(shading_blend_2, cs_diagonal,     CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

    return shading_blend_3;
}
