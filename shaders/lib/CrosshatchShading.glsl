

vec2 level_to_uv_offset(float light_level) {
    float index = floor((1.0 - light_level) * (TOTAL_TILES - 1.0));
    float col = mod(index, GRID_SIZE);
    float row = floor(index / GRID_SIZE);
    return vec2(col, row) / GRID_SIZE;
}

float sample_pencil_shading(float light_level, vec2 face_uv) {
    vec2 layer_uv_shift = level_to_uv_offset(light_level);

    //horizontal sample
    vec2 side_sample_1 = face_uv * crosshatching_tile_size_uv + layer_uv_shift;         
    float cs_horizontal = texture2D(CROSSHATCHING_TEXTURE, side_sample_1).r;

    //vertical sample
    vec2 side_sample_2 = fast_rotate_uv_90(face_uv) * crosshatching_tile_size_uv + layer_uv_shift;         
    float cs_vertical = texture2D(CROSSHATCHING_TEXTURE, side_sample_2).r;

    //diagonal sample
    vec2 diagonal_sample = fast_rotate_uv_45(face_uv) * crosshatching_tile_size_uv + layer_uv_shift;
    float cs_diagonal = texture2D(CROSSHATCHING_TEXTURE, diagonal_sample).r;

    //combine
    float shading_blend_1 = pencil_blend_function(1.0,             cs_horizontal,   CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_2 = pencil_blend_function(shading_blend_1, cs_vertical,     CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_3 = pencil_blend_function(shading_blend_2, cs_diagonal,     CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

    return shading_blend_3;
}
