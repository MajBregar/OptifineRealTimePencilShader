#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"

varying vec2 TexCoords;

#define LIGHT_TEXTURE_LAYERS 64.0

vec2 rotateUV90(vec2 uv) {
    uv -= 0.5;
    uv = vec2(-uv.y, uv.x);
    uv += 0.5;
    return uv;
}

float quantize_light_level(float light_level){
    return floor(light_level * (LIGHT_TEXTURE_LAYERS - 1.0) + 0.5) / (LIGHT_TEXTURE_LAYERS - 1.0);
}

float level_to_offset(float light_level){
    return (floor((1.0 - light_level) * (LIGHT_TEXTURE_LAYERS - 1.0))) / LIGHT_TEXTURE_LAYERS;
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

vec2 get_face_tangent_space_uv(vec3 world_pos, vec3 world_normal) {
    vec3 blending = abs(world_normal);
    blending = normalize(max(blending, 0.0001));
    blending /= (blending.x + blending.y + blending.z);

    vec2 uvX = world_pos.zy;
    vec2 uvY = world_pos.xz;
    vec2 uvZ = world_pos.xy;

    return fract(
        uvX * blending.x +
        uvY * blending.y +
        uvZ * blending.z
    );
}

float sample_pencil_shading(float light_level) {
    vec2 layer_uv_shift = vec2(level_to_offset(light_level), 0.0);
    vec2 layer_uv_adjust = vec2(1.0 / LIGHT_TEXTURE_LAYERS, 1.0);

    vec3 model_pos = texture2D(colortex10, TexCoords).rgb;
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
    if (dot(world_normal, world_y_normal) == 1.0){
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

float remap_sky_light_level(float raw_light){
    return pow(raw_light, 4.0);
}

float remap_block_light_level(float raw_light){
    return 1.1 * pow(raw_light, 2.2);
}

void main() {

    vec4 contour_data = texture2D(colortex7, TexCoords);
    float contour = contour_data.r;
    vec3 background_color = vec3(float(200), float(164), float(130)) / 256.0;


    if (contour_data.a == 1.0 && is_sky(TexCoords)){
        gl_FragData[0] = vec4(background_color * 1.2, 1.0);
        return;
    }

    vec3 fragment_normal = texture2D(colortex11, TexCoords).rgb;
    float fragment_depth_raw = texture2D(depthtex0, TexCoords).r;
    float shading_color_falloff = pow(linearize_to_view_dist(fragment_depth_raw), CONTOUR_COLOR_FALLOFF);;
    
    
    
    //LIGHT CALCULATIONS
    float sun_light_level = max(dot(fragment_normal, normalize(sunPosition)), 0.0);

    float shadow = getSoftShadow(TexCoords, get_shadow_map_clip_pos(TexCoords, fragment_depth_raw)).r;

    float light_block = texture2D(colortex2, TexCoords).r;
    float light_sky = texture2D(colortex2, TexCoords).g;
    float light_map_level = remap_sky_light_level(light_sky) + remap_block_light_level(light_block);

    float final_light_level = clamp(light_map_level + sun_light_level * shadow + AMBIENT_LIGHT, 0.0, 1.0);
    


    float shading_color = is_sky(TexCoords) ? 1.0 : sample_pencil_shading(final_light_level);

    shading_color = shading_color + shading_color_falloff * (1.0 - shading_color); 

    shading_color = pencil_blend_function(min(contour, shading_color), contour, CONTOUR_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);


    vec2 raw_uv = texture2D(colortex3, TexCoords).rg;
    vec3 default_block_color = texture2D(colortex0, TexCoords).rgb;
    vec3 paper_texture_color = texture2D(colortex9, raw_uv).rgb;
    float b = 0.7;


    vec3 texturing_color = (1.0 - b) * paper_texture_color + b * background_color;
    vec3 paper = texturing_color * shading_color;

    vec3 test = vec3(shading_color);

    /* RENDERTARGETS:0 */
    gl_FragData[0] = vec4(test, 1.0);
}

