


const vec3 forward_facing_vector = vec3(0.0, 0.0, 1.0);

float linearize_depth(float z) {
    float ndc = z * 2.0 - 1.0;
    return (2.0 * near * far) / (far + near - ndc * (far - near));
}

bool is_sky(vec2 uv) {
    float depth = texture2D(depthtex1, uv).r;
    return depth == 1.0;
}