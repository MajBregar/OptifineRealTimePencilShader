#version 430
#define COMPOSITE
#define FRAGMENT_SHADER
#include "../lib/Inc.glsl"


varying vec2 TexCoords;

#define DISPLACEMENT_MAP_LAYER_COUNT 3.0
#define LIGHT_TEXTURE_LAYERS 128.0
#define TILE_GRID_SIZE 16.0
#define TOTAL_TILES TILE_GRID_SIZE * TILE_GRID_SIZE

vec2 get_displacement(vec2 uv, float layer) {
    vec2 dmap_sample_uv = vec2((TexCoords.x + layer) / DISPLACEMENT_MAP_LAYER_COUNT, TexCoords.y);
    vec2 encoded = texture2D(DISPLACEMENT_MAP, dmap_sample_uv).rg;
    return vec2((encoded.r - 0.5) * 2.0 * CONTOUR_SHAKE_MAX_DISPLACEMENT, (encoded.g - 0.5) * 2.0 * CONTOUR_SHAKE_MAX_DISPLACEMENT);
}

float get_displaced_fragment_contour_color(vec2 uv, vec2 face_uv){

    vec2 raw_displacement_1 = get_displacement(uv, 0.0);
    vec2 raw_displacement_2 = get_displacement(uv, 1.0);
    vec2 raw_displacement_3 = get_displacement(uv, 2.0);

    float contour_displacement_falloff_1 = 1.0 - pow(texture2D(SHADING_BUFFER_MAIN, clamp(uv + raw_displacement_1, 0.0, 1.0)).a, CONTOUR_DISPLACEMENT_FALLOFF);
    float contour_displacement_falloff_2 = 1.0 - pow(texture2D(SHADING_BUFFER_MAIN, clamp(uv + raw_displacement_2, 0.0, 1.0)).a, CONTOUR_DISPLACEMENT_FALLOFF);
    float contour_displacement_falloff_3 = 1.0 - pow(texture2D(SHADING_BUFFER_MAIN, clamp(uv + raw_displacement_3, 0.0, 1.0)).a, CONTOUR_DISPLACEMENT_FALLOFF);

    vec2 final_contour_displacement_1 = raw_displacement_1 * contour_displacement_falloff_1;
    vec2 final_contour_displacement_2 = raw_displacement_2 * contour_displacement_falloff_2;
    vec2 final_contour_displacement_3 = raw_displacement_3 * contour_displacement_falloff_3;

    float contour_1 = texture2D(SHADING_BUFFER_MAIN, clamp(uv + final_contour_displacement_1, 0.0, 1.0)).r;
    float contour_2 = texture2D(SHADING_BUFFER_MAIN, clamp(uv + final_contour_displacement_2, 0.0, 1.0)).r;
    float contour_3 = texture2D(SHADING_BUFFER_MAIN, clamp(uv + final_contour_displacement_3, 0.0, 1.0)).r;

    float noise = texture2D(noisetex, face_uv).r * CONTOUR_NOISE;

    float c1_blend = pencil_blend_function(1.0,      CONTOUR_CS, clamp(CONTOUR_UB * contour_1 - noise, 0.0, 1.0), CONTOUR_UW, CONTOUR_WP_THRESHOLD);
    float c2_blend = pencil_blend_function(c1_blend, CONTOUR_CS, clamp(CONTOUR_UB * contour_2 - noise, 0.0, 1.0), CONTOUR_UW, CONTOUR_WP_THRESHOLD);
    float c3_blend = pencil_blend_function(c2_blend, CONTOUR_CS, clamp(CONTOUR_UB * contour_3 - noise, 0.0, 1.0), CONTOUR_UW, CONTOUR_WP_THRESHOLD);

    return c3_blend;
}


vec2 level_to_uv_offset(float light_level) {
    float index = floor((1.0 - light_level) * (TOTAL_TILES - 1.0));
    float col = mod(index, TILE_GRID_SIZE);
    float row = floor(index / TILE_GRID_SIZE);

    return vec2(col, row) / TILE_GRID_SIZE;
}

float sample_pencil_shading(float light_level, vec2 face_uv) {
    face_uv = fract(face_uv);

    vec2 layer_uv_shift = level_to_uv_offset(light_level);
    vec2 layer_uv_adjust = vec2(1.0 / TILE_GRID_SIZE, 1.0 / TILE_GRID_SIZE);

    //horizontal sample
    vec2 side_base_1 = face_uv;
    vec2 side_sample_1 = side_base_1 * layer_uv_adjust + layer_uv_shift;         
    float cs_horizontal = texture2D(CROSSHATCHING_TEXTURE, side_sample_1).r;

    //vertical sample
    vec2 side_base_2 = fast_rotate_uv_90(face_uv);
    vec2 side_sample_2 = side_base_2 * layer_uv_adjust + layer_uv_shift;         
    float cs_vertical = texture2D(CROSSHATCHING_TEXTURE, side_sample_2).r;

    //diagonal sample
    vec2 diagonal_base = face_uv;
    vec2 diagonal_uv = rotate_and_mirror_uv(diagonal_base, 0.785399);
    vec2 diagonal_sample = diagonal_uv * layer_uv_adjust + layer_uv_shift;
    float cs_diagonal = texture2D(CROSSHATCHING_TEXTURE, diagonal_sample).r;

    //combine
    float shading_blend_1 = pencil_blend_function(1.0,             cs_horizontal,   CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_2 = pencil_blend_function(shading_blend_1, cs_vertical,   CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_3 = pencil_blend_function(shading_blend_2, cs_diagonal,   CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

    return shading_blend_3;
}


void main() {

    float depth_raw = texture2D(DEPTH_BUFFER_ALL, TexCoords).r;
    vec3 world_normal = texture2D(MODEL_NORMALS, TexCoords).rgb;
    vec3 view_normal = normalize(mat3(gbufferModelView) * world_normal);

    int material = get_id(TexCoords);
    vec2 face_uv = texture2D(TANGENT_SPACE_UVS, TexCoords).xy;        

    float contour_color = get_displaced_fragment_contour_color(TexCoords, face_uv);

    float sun_angle_block = max(dot(view_normal, normalize(sunPosition)), 0.0);

    float sun_brightness = 1.3;
    float sun_angle_world = max(dot(world_y_normal, normalize(mat3(gbufferModelViewInverse) * sunPosition)), 0.0) * sun_brightness;

    float shadow = getSoftShadow(TexCoords, get_shadow_map_clip_pos(TexCoords, depth_raw)).r;
    float sun_light = remap_sun_light_level(min(sun_angle_block, sun_angle_world) * shadow);

    vec2 perceptual_brightness = vec2(eyeBrightnessSmooth) / 240.0;
    float perceptual_b_block = perceptual_brightness.x;
    float perceptual_b_sky = perceptual_brightness.y;

    float light_color = 0.0;
    if (material >= HAND_HOLD_IDS) {
        light_color = perceptual_b_sky * sun_angle_world + perceptual_b_block + sun_light + AMBIENT_LIGHT;
    } else {
        vec2 lightmap_light = get_lightmap_light(TexCoords);
        light_color = lightmap_light.x * sun_angle_world + lightmap_light.y + sun_light + AMBIENT_LIGHT;
    }
    light_color = clamp(light_color, 0.0, 1.0);


    float shading_color = is_sky(TexCoords) ? 1.0 : sample_pencil_shading(light_color, face_uv);
    float final_color = pencil_blend_function(min(contour_color, shading_color), contour_color, CONTOUR_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

    float weight = clamp(1.0 - perceptual_b_sky, 0.0, 1.0);
    float adjusted_block = perceptual_b_block * weight;
    float contrast_adjustment = (adjusted_block + perceptual_b_sky) * 0.06;
    
    
    vec3 output_color = vec3(clamp(final_color - contrast_adjustment, 0.0, 1.0));

    /* RENDERTARGETS:4 */   
    gl_FragData[0] = vec4(output_color, 1.0);
}
