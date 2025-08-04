#version 430
#define COMPOSITE
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"

varying vec2 TexCoords;

void main() {

    //GET FRAGMENT DATA
    int material = get_id(TexCoords);

    float depth_raw = texture2D(DEPTH_BUFFER_ALL, TexCoords).r;
    vec3 world_normal = texture2D(MODEL_NORMALS, TexCoords).rgb;
    vec3 view_normal = normalize(mat3(gbufferModelView) * world_normal);
    vec2 face_uv = texture2D(TANGENT_SPACE_UVS, TexCoords).xy;     


    //LIGHTING CALCULATIONS
    float sun_angle_block = max(dot(view_normal, normalize(sunPosition)), 0.0);
    float sun_brightness = 1.3;
    float sun_angle_world = max(dot(world_y_normal, normalize(mat3(gbufferModelViewInverse) * sunPosition)), 0.0) * sun_brightness;

    float shadow = getSoftShadow(TexCoords, get_shadow_map_clip_pos(TexCoords, depth_raw), face_uv).r;

    float sun_light = remap_sun_light_level(min(sun_angle_block, sun_angle_world) * shadow);

    vec2 perceptual_brightness = vec2(eyeBrightnessSmooth) / 240.0;
    float perceptual_b_block = perceptual_brightness.x;
    float perceptual_b_sky = perceptual_brightness.y;

    //FINAL LIGHT BLEND
    float light_color = 0.0;
    if (is_block(material)) {
        vec2 lightmap_light = get_lightmap_light(TexCoords);
        light_color = lightmap_light.x * sun_angle_world + lightmap_light.y + sun_light + AMBIENT_LIGHT;
    } else if (is_mob(material)) {
        light_color = sun_angle_world + sun_light + AMBIENT_LIGHT;
    } else {
        light_color = perceptual_b_sky * sun_angle_world + perceptual_b_block + sun_light + AMBIENT_LIGHT;
    }
    light_color = clamp(light_color, 0.0, 1.0);


    //TEXTURING
    float contour_color = get_displaced_fragment_contour_color(TexCoords, face_uv);

    float shading_color = material == SKY ? 1.0 : sample_pencil_shading(light_color, face_uv);
    float final_color = pencil_blend_function(min(contour_color, shading_color), contour_color, CONTOUR_UB, CROSSHATCH_UW, CROSSHATCH_WP_THRESHOLD);

    float weight = clamp(1.0 - perceptual_b_sky, 0.0, 1.0);
    float adjusted_block = perceptual_b_block * weight;
    float contrast_adjustment = (adjusted_block + perceptual_b_sky) * 0.06;
    
    vec3 output_color = vec3(clamp(final_color - contrast_adjustment, 0.0, 1.0));

    /* RENDERTARGETS:4 */   
    gl_FragData[0] = vec4(output_color, 1.0);
}
