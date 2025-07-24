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


float blend_function(float ct, float cs, float ub_local) {
    float ca = ct * (1.0 - cs);
    ca = ct >= CROSSHATCH_WP_THRESHOLD ? ca * CROSSHATCH_UW : ca;
    return ct - ub_local * ca;
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

    float angle = radians(-45.0);
    mat2 rotation_matrix = mat2(cos(angle), -sin(angle), sin(angle),  cos(angle));
    vec2 cs2_sample_uv = rotation_matrix * raw_uv ;
    cs2_sample_uv.x = abs(cs2_sample_uv.x);
    cs2_sample_uv = cs2_sample_uv * vec2(1.0 / LIGHT_TEXTURE_LAYERS, 1.0) + vec2(light_offset, 0.0);
    float cs2 = texture2D(colortex6, cs2_sample_uv).r;

    float light_blend = CROSSHATCH_BLENDING_MULTIPLIER * CROSSHATCH_UB * (1.0 - light_level);

    float blend1 = blend_function(1.0, ct, light_blend);
    float blend2 = blend_function(blend1, cs, light_blend);
    float o = light_level > (1.0 - CROSSHATCH_DIAGONAL_CH_THRESHOLD) ? blend2 : blend_function(blend2, cs2, light_blend);
    return o;
}


float blur_contour(vec2 uv) {
    vec2 texelSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    float result = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            result += texture2D(colortex4, uv + offset).r;
        }
    }
    return result / 9.0;
}


void main() {
    float contour = blur_contour(TexCoords);
    vec3 fragment_normal = get_view_space_normal(TexCoords);
    float fragment_depth_raw = texture2D(depthtex0, TexCoords).r;

    //LIGHT CALCULATIONS
    float sun_light_level = max(dot(fragment_normal, normalize(sunPosition)), 0.0);
    float shadow_level = get_shadow(TexCoords, fragment_depth_raw).r;

    float light_block = pow(texture2D(colortex2, TexCoords).r, 5.2) * 2.0;
    float light_sky = pow(texture2D(colortex2, TexCoords).g, 4.0);
    float light_map_level = light_block + light_sky;
    float raw_light_level = light_map_level;


    float final_light_level = raw_light_level + sun_light_level * shadow_level + AMBIENT_LIGHT; 
    float light_level = quantize_light_level(final_light_level);

    float out_color = 1.0;

    if (!is_sky(TexCoords)) {
        out_color = sample_pencil_shading(light_level);
    }

    out_color = min(out_color, contour);


    /* RENDERTARGETS:0 */
    gl_FragData[0] = vec4(out_color);
}

