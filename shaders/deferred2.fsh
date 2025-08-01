#version 120
#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

varying vec2 TexCoords;

#define DISPLACEMENT_MAP_LAYER_COUNT 3.0
#define LIGHT_TEXTURE_LAYERS 128.0
#define TILE_GRID_SIZE 16.0
#define TOTAL_TILES TILE_GRID_SIZE * TILE_GRID_SIZE

vec2 get_displacement(vec2 uv, float layer) {
    vec2 dmap_sample_uv = vec2((TexCoords.x + layer) / DISPLACEMENT_MAP_LAYER_COUNT, TexCoords.y);
    vec2 encoded = texture2D(colortex5, dmap_sample_uv).rg;
    return vec2((encoded.r - 0.5) * 2.0 * CONTOUR_SHAKE_MAX_DISPLACEMENT, (encoded.g - 0.5) * 2.0 * CONTOUR_SHAKE_MAX_DISPLACEMENT);
}

float get_displaced_fragment_contour_color(vec2 uv, vec2 face_uv){
    vec2 raw_displacement_1 = get_displacement(uv, 0.0);
    vec2 raw_displacement_2 = get_displacement(uv, 1.0);
    vec2 raw_displacement_3 = get_displacement(uv, 2.0);

    float contour_displacement_falloff_1 = pow(texture2D(colortex4, clamp(uv + raw_displacement_1, 0.0, 1.0)).a, CONTOUR_DISPLACEMENT_FALLOFF);
    float contour_displacement_falloff_2 = pow(texture2D(colortex4, clamp(uv + raw_displacement_2, 0.0, 1.0)).a, CONTOUR_DISPLACEMENT_FALLOFF);
    float contour_displacement_falloff_3 = pow(texture2D(colortex4, clamp(uv + raw_displacement_3, 0.0, 1.0)).a, CONTOUR_DISPLACEMENT_FALLOFF);

    vec2 final_contour_displacement_1 = raw_displacement_1 * contour_displacement_falloff_1;
    vec2 final_contour_displacement_2 = raw_displacement_2 * contour_displacement_falloff_2;
    vec2 final_contour_displacement_3 = raw_displacement_3 * contour_displacement_falloff_3;

    float contour_1 = texture2D(colortex4, clamp(uv + final_contour_displacement_1, 0.0, 1.0)).r;
    float contour_2 = texture2D(colortex4, clamp(uv + final_contour_displacement_2, 0.0, 1.0)).r;
    float contour_3 = texture2D(colortex4, clamp(uv + final_contour_displacement_3, 0.0, 1.0)).r;

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

float sample_pencil_shading(float light_level, vec3 world_normal, vec3 world_pos, vec2 face_uv) {

    float bias = 0.0;
    light_level = clamp(light_level + bias, 0.0, 1.0);


    vec2 layer_uv_shift = level_to_uv_offset(light_level);
    vec2 layer_uv_adjust = vec2(1.0 / TILE_GRID_SIZE, 1.0 / TILE_GRID_SIZE);

    vec2 base_face_uv = face_uv;
    
    //vec3 raw_noise = texture2D(noisetex, base_face_uv).rgb;


    //horizontal sample
    vec2 side_base_1 = base_face_uv;
    vec2 side_sample_1 = side_base_1 * layer_uv_adjust + layer_uv_shift;         
    float cs_horizontal = texture2D(colortex6, side_sample_1).r;

    vec2 side_base_2 = fast_rotate_uv_90(base_face_uv);
    vec2 side_sample_2 = side_base_2 * layer_uv_adjust + layer_uv_shift;         
    float cs_vertical = texture2D(colortex6, side_sample_2).r;

    //diagonal sample
    float cs_diagonal = 0.0;
    if (dot(world_normal, world_y_normal) >= 1.99){
        //shadow on ground
        vec3 sun_world_normal = normalize((gbufferModelViewInverse * vec4(normalize(sunPosition), 0.0)).xyz);
        vec2 sun_projection = normalize(sun_world_normal.xz);
        float sun_angle = atan(sun_projection.x, -sun_projection.y);

        float section = pi / 60.0;
        sun_angle = sun_angle - mod(sun_angle, section);

        vec2 sun_rot_base1 = rotate_and_mirror_uv(world_pos.xz, sun_angle);
        vec2 sun_rot_sample1 = sun_rot_base1 * layer_uv_adjust + layer_uv_shift;

        vec2 sun_rot_base2 = rotate_and_mirror_uv(world_pos.xz, sun_angle + 0.785399);
        vec2 sun_rot_sample2 = sun_rot_base2 * layer_uv_adjust + layer_uv_shift;

        cs_horizontal = texture2D(colortex6, sun_rot_sample1).r;
        cs_diagonal = texture2D(colortex6, sun_rot_sample2).r;

        
    } else {
        vec2 diagonal_base = abs(dot(world_normal, world_x_normal))  >= 0.99 ? world_pos.yz : (abs(dot(world_normal, world_z_normal))  >= 0.99 ?  world_pos.xy : world_pos.xz);
        
        vec2 diagonal_uv = rotate_and_mirror_uv(diagonal_base, 0.785399);
        vec2 diagonal_sample = diagonal_uv * layer_uv_adjust + layer_uv_shift;
        cs_diagonal = texture2D(colortex6, diagonal_sample).r;

    } 
    

    float shading_blend_1 = pencil_blend_function(1.0,             cs_horizontal,   CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_2 = pencil_blend_function(shading_blend_1, cs_vertical,   CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_3 = pencil_blend_function(shading_blend_2, cs_diagonal,   CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

    return shading_blend_3;
}


void main() {



    vec3 model_pos = texture2D(colortex2, TexCoords).rgb;
    vec3 world_pos = model_pos + cameraPosition;
    vec3 world_normal = texture2D(colortex1, TexCoords).rgb;

    vec2 face_uv = get_face_tangent_space_uv(world_pos, world_normal);

    bool hand_shading = false;
    if (world_normal.x > 1.0) {
        world_normal -= 10.0;
        hand_shading = true;
    }


    float contour_color = get_displaced_fragment_contour_color(TexCoords, face_uv);

    vec3 view_normal = normalize(mat3(gbufferModelView) * world_normal);
    float depth_raw = texture2D(depthtex0, TexCoords).r;
    //float shading_color_falloff = pow(linearize_to_view_dist(depth_raw), CONTOUR_COLOR_FALLOFF);

    float sun_angle_block = max(dot(view_normal, normalize(sunPosition)), 0.0);

    if (hand_shading) {
        float hand_simple_shading = clamp(min(contour_color, (sun_angle_block + 0.5)), 0.0, 1.0);
        gl_FragData[0] = vec4(vec3(hand_simple_shading), 1.0);
        return;
    }

    float sun_angle_world = max(dot(world_y_normal, normalize(mat3(gbufferModelViewInverse) * sunPosition)), 0.0);
    sun_angle_world = sun_angle_world == 0.0 ? 0.0 : clamp(sun_angle_world, 0.3, 0.6); //this needs serious tweeking

    float shadow = getSoftShadow(TexCoords, get_shadow_map_clip_pos(TexCoords, depth_raw)).r;
    float sun_light = remap_sun_light_level(min(sun_angle_block, sun_angle_world) * shadow);
    
    vec2 lightmap_light = get_lightmap_light(TexCoords);

    

    float light_color = lightmap_light.x * sun_angle_world + lightmap_light.y + sun_light + AMBIENT_LIGHT;
    light_color = clamp(light_color, 0.0, 1.0);


    
    float shading_color = is_sky(TexCoords) ? 1.0 : sample_pencil_shading(light_color, world_normal, world_pos, face_uv);


    float final_color = pencil_blend_function(min(contour_color, shading_color), contour_color, CONTOUR_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

    vec2 perceptual_brightness = vec2(eyeBrightnessSmooth) / 240.0;
    float block = perceptual_brightness.x;
    float sky = perceptual_brightness.y;

    // Suppress block influence in bright environments
    float weight = clamp(1.0 - sky, 0.0, 1.0);  // near 1 in caves, near 0 outdoors
    float adjusted_block = block * weight;

    float contrast_adjustment = (adjusted_block + sky) * 0.06;
    
    final_color = final_color == 1.0 ? 1.0 : clamp(final_color - contrast_adjustment, 0.0, 1.0);

    /* RENDERTARGETS:4 */   
    gl_FragData[0] = vec4(vec3(final_color), 1.0);
}
