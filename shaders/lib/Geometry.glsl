
vec3 apply_projection_matrix_homogenous(mat4 matrix, vec3 pos){
  vec4 hom = matrix * vec4(pos, 1.0);
  return hom.xyz / hom.w;
}

vec3 screen_to_view_space(vec3 fragment_screen_space) {
    vec3 NDC = fragment_screen_space * 2.0 - 1.0;
    vec4 deprojected_pos = gbufferProjectionInverse * vec4(NDC, 1.0);
    return deprojected_pos.xyz / deprojected_pos.w;
}

vec3 view_to_player_feet_space(vec3 view_space_pos) {
    return mat3(gbufferModelViewInverse) * view_space_pos + gbufferModelViewInverse[3].xyz;
}

float linearize_depth(float d) {
  float z_n = d * 2.0 - 1.0;
  float z_eye = (2.0 * near * far) / (far + near - z_n * (far - near));
  return z_eye;
}

float normalize_to_view_dist(float depth){
  return clamp(linearize_depth(depth) / min(far, float(CONTOUR_VIEW_DISTANCE)), 0.0, 1.0);
}

vec2 mirror_uv(vec2 uv){
    vec2 mirrored_uv = fract(uv);
    mirrored_uv.x = int(floor(uv.x)) % 2 != 0 ? 1.0 - mirrored_uv.x : mirrored_uv.x;
    mirrored_uv.y = int(floor(uv.y)) % 2 != 0 ? 1.0 - mirrored_uv.y : mirrored_uv.y;
    return mirrored_uv;
}

vec2 fast_rotate_uv_45(vec2 uv) {
    const float sincos = 0.70710678;
    uv -= 0.5;
    vec2 rotated = vec2(sincos * uv.x - sincos * uv.y, sincos * uv.x + sincos * uv.y);
    return mirror_uv(rotated + 0.5);
}

vec2 fast_rotate_uv_90(vec2 uv){
    uv -= 0.5;
    vec2 rotated = vec2(-uv.y, uv.x);
    return rotated + 0.5;
}

vec2 rotate_and_mirror_uv(vec2 uv, float ang_rad){
    float cosang = cos(ang_rad);
    float sinang = sin(ang_rad);
    vec2 rotated = mat2(cosang, -sinang, sinang,  cosang) * uv;
    return mirror_uv(rotated);
}










vec2 get_skybox_uv(vec3 screen_fragcoords){

    vec2 screen_uv = screen_fragcoords.xy / vec2(viewWidth, viewHeight);

    vec2 NDC = screen_uv * 2.0 - 1.0;

    float fx_inv = gbufferProjectionInverse[0][0];
    float fy_inv = gbufferProjectionInverse[1][1];

    vec3 ray = vec3(
        NDC.x * fx_inv,
        NDC.y * fy_inv,
        -1.0
    );

    vec3 ray_world = mat3(gbufferModelViewInverse) * ray.xyz;

    //2 y planes
    if (abs(ray_world.y) > 0.0001) {
        
        vec3 hit = ray_world / ray_world.y;

        if (abs(hit.x) <= 1.0 && abs(hit.z) <= 1.0){

            vec2 local = vec2(hit.x, hit.z);
            vec2 uv = fract((local * 0.5 + 0.5) * SKY_CUBEMAP_TILE_SIZE);

            return uv;
        } 
    }

    //2 z planes
    if (abs(ray_world.z) > 0.0001) {

        vec3 hit = ray_world / ray_world.z;

        if (abs(hit.x) <= 1.0 && abs(hit.y) <= 1.0){

            vec2 local = vec2(hit.x, hit.y);
            vec2 uv = fract((local * 0.5 + 0.5) * SKY_CUBEMAP_TILE_SIZE);

            return uv;
        } 
    }

    //2 x planes
    if (abs(ray_world.x) > 0.0001) {

        vec3 hit = ray_world / ray_world.x;

        if (abs(hit.y) <= 1.0 && abs(hit.z) <= 1.0){

            vec2 local = vec2(hit.z, hit.y);
            vec2 uv = fract((local * 0.5 + 0.5) * SKY_CUBEMAP_TILE_SIZE);

            return uv;
        } 
    }


    return vec2(0.0);
}

