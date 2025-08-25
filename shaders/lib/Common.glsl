

const vec3 world_x_normal = vec3(1.0, 0.0, 0.0);
const vec3 world_y_normal = vec3(0.0, 1.0, 0.0);
const vec3 world_z_normal = vec3(0.0, 0.0, 1.0);
const vec3 forward_facing_vector = vec3(0.0, 0.0, 1.0);

const vec3 tangent_space_horizontal = vec3(1.0, 0.0, 0.0);
const vec3 tangent_space_vertical = vec3(0.0, 1.0, 0.0);
const vec3 tangent_space_45deg = vec3(0.707, 0.707, 0.0);

vec2 texelSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);

const vec2 mipmap_inverse_aspect_ratio = vec2(2.0 / 3.0, 1.0);
vec2 crosshatching_tile_size_uv = vec2(1.0 / GRID_SIZE, 1.0 / GRID_SIZE);

float pencil_blend_function(float ct, float cs, float mub, float muw, float thr) {
    float ca = ct * (1.0 - cs);
    ca = ct >= thr ? ca * muw : ca;
    return ct - mub * ca;
}


