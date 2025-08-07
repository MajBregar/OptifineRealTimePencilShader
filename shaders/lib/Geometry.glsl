
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

vec2 get_skybox_uv(vec2 screen_fragcoords){

    vec2 screen_uv = screen_fragcoords / vec2(viewWidth, viewHeight);

    vec2 NDC = screen_uv * 2.0 - 1.0;
    NDC.x *= aspectRatio;

    vec3 cubemap_center = SKY_CUBEMAP_DIST * floor(cameraPosition / SKY_CUBEMAP_DIST + 0.5);
    vec3 ray_view = normalize(vec3(NDC, -1.0));
    vec3 ray_world = normalize((gbufferModelViewInverse * vec4(ray_view, 0.0)).xyz);

    //2 y planes
    for (int dir = -1; dir <= 1; dir += 2) {
        if (abs(ray_world.y) <= 0.0001) continue;

        float t = (SKY_CUBEMAP_DIST * dir) / ray_world.y;
        vec3 hit = cubemap_center + ray_world * t;

        if (abs(hit.x - cubemap_center.x) <= SKY_CUBEMAP_DIST && abs(hit.z - cubemap_center.z) <= SKY_CUBEMAP_DIST) return fract(hit.xz * SKY_CUBEMAP_TILE_SIZE);
    }

    //2 z planes
    for (int dir = -1; dir <= 1; dir += 2) {
        if (abs(ray_world.z) <= 0.0001) continue;

        float t = (SKY_CUBEMAP_DIST * dir) / ray_world.z;
        vec3 hit = cubemap_center + ray_world * t;

        if (abs(hit.x - cubemap_center.x) <= SKY_CUBEMAP_DIST && abs(hit.y - cubemap_center.y) <= SKY_CUBEMAP_DIST) return fract(hit.xy * SKY_CUBEMAP_TILE_SIZE);
    }

    //2 x planes
    for (int dir = -1; dir <= 1; dir += 2) {
        if (abs(ray_world.x) <= 0.0001) continue;

        float t = (SKY_CUBEMAP_DIST * dir) / ray_world.x;
        vec3 hit = cubemap_center + ray_world * t;

        if (abs(hit.y - cubemap_center.y) <= SKY_CUBEMAP_DIST && abs(hit.z - cubemap_center.z) <= SKY_CUBEMAP_DIST) return fract(hit.zy * SKY_CUBEMAP_TILE_SIZE);
    }

    return vec2(0.0);
}

vec2 get_skysphere_uv(vec2 screen_uv) {
    vec2 NDC = screen_uv * 2.0 - 1.0;
    NDC.x *= aspectRatio;

    vec3 cubemap_center = SKY_CUBEMAP_DIST * floor(cameraPosition / SKY_CUBEMAP_DIST + 0.5);
    vec3 ray_view = normalize(vec3(NDC, -1.0));
    vec3 ray_world = normalize((gbufferModelViewInverse * vec4(ray_view, 0.0)).xyz);

    // For spherical UV projection, compute UVs from direction
    float u = atan(ray_world.z, ray_world.x) / (2.0 * 3.14159265) + 0.5;
    float v = acos(clamp(ray_world.y, -1.0, 1.0)) / 3.14159265;

    return fract(vec2(u, v) * SKY_CUBEMAP_TILE_SIZE);
}


