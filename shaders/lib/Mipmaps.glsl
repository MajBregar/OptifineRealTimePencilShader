#if defined(FRAGMENT_SHADER) && defined(GBUFFERS)
//only works in gbuffer fragment shader stages    
float calculate_mip_level(vec2 uvs){
    vec2 dx = dFdx(uvs * vec2(MIPMAP_TILE_RESOLUTION));
    vec2 dy = dFdy(uvs * vec2(MIPMAP_TILE_RESOLUTION));
    float d_sqared = max(dot(dx, dx), dot(dy, dy));
    float m = log2(d_sqared);
    return clamp((DERIVATIVE_MIPMAP_CALC_MULTIPLIER * m) / MAX_MIP, 0.0, 1.0);
}
#endif

float calculate_mip_level_depth(float depth) {
    float d = linearize_depth(depth);
    return clamp((DEPTH_MIPMAP_CALC_MULTIPLIER * log2(d) - DEPTH_MIPMAP_CALC_ADJUST) / MAX_MIP, 0.0, 1.0);
}


vec3 read_mip_level(vec2 screen_sample) {
    float mip = texture2D(TANGENT_SPACE_UVS, screen_sample).b * MAX_MIP;
    float main_mip = floor(mip);
    float higher_mip = ceil(mip);
    float interp = fract(mip);
    return vec3(main_mip, higher_mip, interp);
}

vec2 get_mip_layer_origin(int mip_level){
    if (mip_level == 0) return vec2(0.0);
    if (mip_level == 1) return vec2(2.0 / 3.0, 0.0);
    if (mip_level == 2) return vec2(2.0 / 3.0, 0.5);

    int mip_devision = 1 << (mip_level - 1);
    float grid_origin_offset = (1.0 - 1.0 / mip_devision - 0.5) * 2.0 / 3.0; // (1 - (1/2)^n-1 - 1/2) * 2/3
    
    return vec2(2.0 / 3.0 + grid_origin_offset, 0.5);
}


//GRID MIPPED TEXTURE SAMPLING
vec2 index_to_tile_origin(float index) {
    float col = mod(index, GRID_SIZE);
    float row = floor(index / GRID_SIZE);
    return vec2(col, row) / GRID_SIZE;
}

vec2 get_grid_mipmap_uv(vec2 tile_space_uv, int tile_index, int mip_level) {

    vec2 grid_tile_size_texture_uv = vec2(1.0 / GRID_SIZE, 1.0 / GRID_SIZE) * mipmap_inverse_aspect_ratio;

    vec2 tile_origin_in_grid_space = index_to_tile_origin(float(tile_index));

    int mip_devision = 1 << mip_level;
    float mip_scalar = 1.0 / mip_devision; //instead of pow(0.5, mip)

    vec2 tile_origin_in_grid_space_adjusted_for_mip = tile_origin_in_grid_space * mip_scalar;

    vec2 grid_origin_in_texture_space = get_mip_layer_origin(mip_level);

    vec2 tile_origin_in_texture_space = grid_origin_in_texture_space + tile_origin_in_grid_space_adjusted_for_mip * mipmap_inverse_aspect_ratio;

    vec2 tile_space_uv_scaled_for_texture_space = tile_space_uv * grid_tile_size_texture_uv * mip_scalar;

    vec2 texture_space_sample = tile_space_uv_scaled_for_texture_space + tile_origin_in_texture_space;

    return texture_space_sample;
}

int light_to_index(float light){
    return int((1.0 - light) * (TOTAL_TILES - 1.0));
}


//NORMAL MIPPED TEXTURE SAMPLING
vec2 get_mipmap_uv(vec2 sample_uv, int mip_level){

    vec2 mip_layer_texture_space_origin = get_mip_layer_origin(mip_level);

    int mip_devision = 1 << (mip_level);
    float mip_scalar = 1.0 / mip_devision;

    vec2 sample_uv_scaled = sample_uv * mip_scalar * mipmap_inverse_aspect_ratio;

    return clamp(mip_layer_texture_space_origin + sample_uv_scaled, 0.0, 1.0);
}

vec3 sample_grayscale_mip_interpolated(sampler2D texture_sampler, vec2 sample_uv, vec2 screen_sample){
    sample_uv = sample_uv * 0.9999;

    vec3 mip_levels = read_mip_level(screen_sample);

    vec2 main_mip_sample_uv = get_mipmap_uv(sample_uv, int(mip_levels.x + 0.5));
    vec2 higher_mip_sample_uv = get_mipmap_uv(sample_uv, int(mip_levels.y + 0.5));

    float main_layer =   texture2D(texture_sampler, main_mip_sample_uv).r;
    float higher_layer = texture2D(texture_sampler, higher_mip_sample_uv).r;
    return vec3((1.0 - mip_levels.z) * main_layer + mip_levels.z * higher_layer);
}


vec3 sample_mip_interpolated(sampler2D texture_sampler, vec2 sample_uv, vec2 screen_sample){
    sample_uv = sample_uv * 0.9999;

    vec3 mip_levels = read_mip_level(screen_sample);

    vec2 main_mip_sample_uv = get_mipmap_uv(sample_uv, int(mip_levels.x + 0.5));
    vec2 higher_mip_sample_uv = get_mipmap_uv(sample_uv, int(mip_levels.y + 0.5));

    vec3 main_layer =   texture2D(texture_sampler, main_mip_sample_uv).rgb;
    vec3 higher_layer = texture2D(texture_sampler, higher_mip_sample_uv).rgb;
    return (1.0 - mip_levels.z) * main_layer + mip_levels.z * higher_layer;
}



//GRID MIPMAP SAMPLING
float sample_grayscale_grid_mip_interpolated(vec2 tile_space_uv, int tile_id, vec3 mip_levels){
    vec2 main_mip_sample_uv = get_grid_mipmap_uv(tile_space_uv, tile_id, int(mip_levels.x + 0.5));
    vec2 higher_mip_sample_uv = get_grid_mipmap_uv(tile_space_uv, tile_id, int(mip_levels.y + 0.5));

    float grayscale_main =   texture2D(CROSSHATCHING_TEXTURE, main_mip_sample_uv).r;
    float grayscale_higher = texture2D(CROSSHATCHING_TEXTURE, higher_mip_sample_uv).r;

    return (1.0 - mip_levels.z) * grayscale_main + mip_levels.z * grayscale_higher;
}