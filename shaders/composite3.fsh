#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"

varying vec2 TexCoords;

#define LIGHT_TEXTURE_LAYERS 128.0

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


float sample_pencil_shading(float light_level){

    float light_offset = level_to_offset(light_level);

    vec2 raw_uv = texture2D(colortex3, TexCoords).rg;
    vec2 local_uv = raw_uv * vec2(1.0 / LIGHT_TEXTURE_LAYERS, 1.0);
    vec2 local_uv_rot = rotateUV90(raw_uv) * vec2(1.0 / LIGHT_TEXTURE_LAYERS, 1.0);

    vec2 ct_sample_uv = vec2(local_uv.x + light_offset, local_uv.y);
    float ct = texture2D(colortex6, ct_sample_uv).r;

    vec2 cs_sample_uv = vec2(local_uv_rot.x + light_offset, local_uv_rot.y);
    float cs = texture2D(colortex6, cs_sample_uv).r;


    vec3 sun_view = normalize(sunPosition);
    vec3 sun_world = normalize((gbufferModelViewInverse * vec4(sun_view, 0.0)).xyz);
    vec2 sunXZ = normalize(sun_world.xz);
    float sunYaw = atan(sunXZ.x, -sunXZ.y);
    float angle = sunYaw;

    mat2 rotation_matrix = mat2(cos(angle), -sin(angle), sin(angle),  cos(angle));
    vec2 cs2_sample_uv = rotation_matrix * raw_uv ;
    cs2_sample_uv.x = abs(cs2_sample_uv.x);
    cs2_sample_uv = cs2_sample_uv * vec2(1.0 / LIGHT_TEXTURE_LAYERS, 1.0) + vec2(light_offset, 0.0);
    float cs2 = texture2D(colortex6, cs2_sample_uv).r;

    float light_blend = CROSSHATCH_BLENDING_MULTIPLIER * CROSSHATCH_UB * (1.0 - light_level);

    float blend1 = pencil_blend_function(1.0, ct, light_blend, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float blend2 = pencil_blend_function(blend1, cs, light_blend, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);
    float o = light_level > (1.0 - CROSSHATCH_DIAGONAL_CH_THRESHOLD) ? blend2 : pencil_blend_function(blend2, cs2, light_blend, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

    return o;
}

float remap_sky_light_level(float raw_light){
    return pow(raw_light, 4.0);
}

float remap_block_light_level(float raw_light){
    return 1.1 * pow(raw_light, 2.2);
}

void main() {
    float contour = texture2D(colortex7, TexCoords).r;

    vec3 fragment_normal = texture2D(colortex11, TexCoords).rgb;
    float fragment_depth_raw = texture2D(depthtex0, TexCoords).r;
    float view_depth_falloff = linearize_to_view_dist(fragment_depth_raw);

    //LIGHT CALCULATIONS
    float sun_light_level = max(dot(fragment_normal, normalize(sunPosition)), 0.0);

    float shadow = getSoftShadow(TexCoords, get_shadow_map_clip_pos(TexCoords, fragment_depth_raw)).r;

    float light_block = texture2D(colortex2, TexCoords).r;
    float light_sky = texture2D(colortex2, TexCoords).g;
    float light_map_level = remap_sky_light_level(light_sky) + remap_block_light_level(light_block);

    float final_light_level = clamp(light_map_level + sun_light_level * shadow + AMBIENT_LIGHT, 0.0, 1.0);
    


    float shading_color = is_sky(TexCoords) ? 1.0 : sample_pencil_shading(final_light_level);
    shading_color = view_depth_falloff + shading_color; 
    shading_color = pencil_blend_function(min(contour, shading_color), contour, 1.0, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);



    vec2 raw_uv = texture2D(colortex3, TexCoords).rg;
    vec3 default_block_color = texture2D(colortex0, TexCoords).rgb;
    vec3 paper_texture_color = texture2D(colortex9, raw_uv).rgb;
    float b = 0.0;

    vec3 background_color = vec3(float(200), float(164), float(130)) / 256.0;

    vec3 texturing_color = (1.0 - b) * paper_texture_color + b * default_block_color;
    vec3 paper = texturing_color * shading_color;

    /* RENDERTARGETS:0 */
    gl_FragData[0] = vec4(paper, 1.0);
}

