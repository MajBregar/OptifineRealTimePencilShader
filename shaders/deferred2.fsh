#version 120
#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

varying vec2 TexCoords;

#define DISPLACEMENT_MAP_LAYER_COUNT 3.0
#define LIGHT_TEXTURE_LAYERS 64.0


vec2 get_displacement(vec2 uv, float layer) {
    vec2 dmap_sample_uv = vec2((TexCoords.x + layer) / DISPLACEMENT_MAP_LAYER_COUNT, TexCoords.y);
    vec2 encoded = texture2D(colortex5, dmap_sample_uv).rg;
    return vec2((encoded.r - 0.5) * 2.0 * CONTOUR_SHAKE_MAX_DISPLACEMENT, (encoded.g - 0.5) * 2.0 * CONTOUR_SHAKE_MAX_DISPLACEMENT);
}

float get_displaced_fragment_contour_color(vec2 uv, vec3 world_pos, vec3 world_normal){
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

    vec2 face_uv = get_face_tangent_space_uv(world_pos, world_normal);
    float noise = texture2D(noisetex, face_uv).r * CONTOUR_NOISE;

    float c1_blend = pencil_blend_function(1.0,      CONTOUR_CS, clamp(CONTOUR_UB * contour_1 - noise, 0.0, 1.0), CONTOUR_UW, CONTOUR_WP_THRESHOLD);
    float c2_blend = pencil_blend_function(c1_blend, CONTOUR_CS, clamp(CONTOUR_UB * contour_2 - noise, 0.0, 1.0), CONTOUR_UW, CONTOUR_WP_THRESHOLD);
    float c3_blend = pencil_blend_function(c2_blend, CONTOUR_CS, clamp(CONTOUR_UB * contour_3 - noise, 0.0, 1.0), CONTOUR_UW, CONTOUR_WP_THRESHOLD);

    return c3_blend;
}


float remap_sky_light_level(float raw_light){
    return pow(raw_light, 4.0);
}

float remap_block_light_level(float raw_light){
    return 1.1 * pow(raw_light, 2.2);
}

float get_fragment_light_level(vec2 uv, vec3 view_normal, float depth_raw){
    float sun_light_level = max(dot(view_normal, normalize(sunPosition)), 0.0);
    float shadow = getSoftShadow(TexCoords, get_shadow_map_clip_pos(TexCoords, depth_raw)).r;
    vec2 lightmap_levels = texture2D(colortex3, TexCoords).rg;
    float light_map_level = remap_sky_light_level(lightmap_levels.g) + remap_block_light_level(lightmap_levels.r);

    return clamp(light_map_level + sun_light_level * shadow + AMBIENT_LIGHT, 0.0, 1.0);
}

float quantize_light_level(float light_level){
    return floor(light_level * (LIGHT_TEXTURE_LAYERS - 1.0) + 0.5) / (LIGHT_TEXTURE_LAYERS - 1.0);
}

float level_to_offset(float light_level){
    return (floor((1.0 - light_level) * (LIGHT_TEXTURE_LAYERS - 1.0))) / LIGHT_TEXTURE_LAYERS;
}

float sample_pencil_shading(float light_level) {
    vec2 layer_uv_shift = vec2(level_to_offset(light_level), 0.0);
    vec2 layer_uv_adjust = vec2(1.0 / LIGHT_TEXTURE_LAYERS, 1.0);

    vec3 model_pos = texture2D(colortex2, TexCoords).rgb;
    vec3 world_normal = texture2D(colortex1, TexCoords).rgb;

    vec3 world_pos = model_pos + cameraPosition;    
    vec2 base_face_uv = get_face_tangent_space_uv(world_pos, world_normal);
    
    //horizontal sample
    vec2 side_base_1 = base_face_uv;
    //side_base_1 = pow(base_face_uv, vec2(0.5));

    vec2 side_sample_1 = side_base_1 * layer_uv_adjust + layer_uv_shift;         
    float cs_face_1 = texture2D(colortex6, side_sample_1).r;
    //vertical sample
    vec2 side_base_2 = fast_rotate_uv_90(base_face_uv);
    //side_base_2 = pow(side_base_2, vec2(0.5));

    vec2 side_sample_2 = side_base_2 * layer_uv_adjust + layer_uv_shift;         
    float cs_face_2 = texture2D(colortex6, side_sample_2).r;

    //diagonal sample
    float cs_diagonal;
    if (dot(world_normal, world_y_normal) >= 0.99){
        //shadow on ground
        vec3 sun_world_normal = normalize((gbufferModelViewInverse * vec4(normalize(sunPosition), 0.0)).xyz);
        vec2 sun_projection = normalize(sun_world_normal.xz);
        float sun_angle = atan(sun_projection.x, -sun_projection.y);

        vec2 sun_rot_base = rotate_and_mirror_uv(world_pos.xz, sun_angle);
        vec2 sun_rot_sample = sun_rot_base * layer_uv_adjust + layer_uv_shift;
        cs_diagonal = texture2D(colortex6, sun_rot_sample).r;
    } else {
        //shadow on face
        vec2 diagonal_base = fast_rotate_uv_45(base_face_uv);
        diagonal_base = abs(diagonal_base);
        vec2 diagonal_sample = diagonal_base * layer_uv_adjust + layer_uv_shift;         
        cs_diagonal = texture2D(colortex6, diagonal_sample).r;
    }
    
    vec3 raw_noise = texture2D(noisetex, base_face_uv).rgb;
    float ub_noise = (raw_noise.r * 2.0 - 1.0) * 0.0;
    float c_noise = (raw_noise.g * 2.0 - 1.0) * 0.0;

    float shading_blend_1 = pencil_blend_function(1.0,             clamp(cs_face_1 + c_noise, 0.0, 1.0),   CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_2 = pencil_blend_function(shading_blend_1, clamp(cs_face_2 + c_noise, 0.0, 1.0),   CROSSHATCH_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float shading_blend_3 = pencil_blend_function(shading_blend_2, clamp(cs_diagonal + c_noise, 0.0, 1.0), clamp(CROSSHATCH_UB + ub_noise, 0.0, 1.0), CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

    return shading_blend_3;
}


void main() {

    vec3 model_pos = texture2D(colortex2, TexCoords).rgb;
    vec3 world_pos = model_pos + cameraPosition;
    vec3 world_normal = texture2D(colortex1, TexCoords).rgb;
    vec3 view_normal = normalize(mat3(gbufferModelView) * world_normal);
    float depth_raw = texture2D(depthtex0, TexCoords).r;
    float shading_color_falloff = pow(linearize_to_view_dist(depth_raw), CONTOUR_COLOR_FALLOFF);


    float contour_color = get_displaced_fragment_contour_color(TexCoords, world_pos, world_normal);
    float light_color = get_fragment_light_level(TexCoords, view_normal, depth_raw);


    float shading_color = is_sky(TexCoords) ? 1.0 : sample_pencil_shading(light_color);
    shading_color = shading_color + shading_color_falloff * (1.0 - shading_color); 
    shading_color = pencil_blend_function(min(contour_color, shading_color), contour_color, CONTOUR_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

    /* RENDERTARGETS:4 */
    gl_FragData[0] = vec4(vec3(shading_color), 1.0);
}
