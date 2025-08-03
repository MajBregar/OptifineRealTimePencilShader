




float linearize_depth(float d) {
  float z_n = d * 2.0 - 1.0;
  float z_eye = (2.0 * near * far) / (far + near - z_n * (far - near));
  return z_eye;
}

float normalize_to_view_dist(float depth){
  return clamp(linearize_depth(depth) / min(far, float(CONTOUR_VIEW_DISTANCE)), 0.0, 1.0);
}

bool is_sky(vec2 uv) {
    float depth = texture2D(DEPTH_BUFFER_TRANSPARENT, uv).r;
    return depth == 1.0;
}

vec2 fast_rotate_uv_45(vec2 uv) {
    const float sincos = 0.70710678;
    uv -= 0.5;
    vec2 rotated = vec2(sincos * uv.x - sincos * uv.y, sincos * uv.x + sincos * uv.y);
    return rotated + 0.5;
}

vec2 fast_rotate_uv_90(vec2 uv){
    uv -= 0.5;
    vec2 rotated = vec2(-uv.y, uv.x);
    return rotated + 0.5;
}

vec2 mirror_uv(vec2 uv){
    vec2 mirrored_uv = fract(uv);
    mirrored_uv.x = int(floor(uv.x)) % 2 != 0 ? 1.0 - mirrored_uv.x : mirrored_uv.x;
    mirrored_uv.y = int(floor(uv.y)) % 2 != 0 ? 1.0 - mirrored_uv.y : mirrored_uv.y;
    return mirrored_uv;
}

vec2 rotate_and_mirror_uv(vec2 uv, float ang_rad){
    float cosang = cos(ang_rad);
    float sinang = sin(ang_rad);
    vec2 rotated = mat2(cosang, -sinang, sinang,  cosang) * uv;
    return mirror_uv(rotated);
}

vec2 get_block_face_tangent_space_uv(vec3 world_pos, vec3 world_normal) {
    vec3 blending = abs(world_normal);
    blending = normalize(max(blending, 0.0001));
    blending /= (blending.x + blending.y + blending.z);

    vec2 uvX = fract(world_pos.zy);
    vec2 uvY = fract(world_pos.xz);
    vec2 uvZ = fract(world_pos.xy);

    return fract(
        uvX * blending.x +
        uvY * blending.y +
        uvZ * blending.z
    );
}

