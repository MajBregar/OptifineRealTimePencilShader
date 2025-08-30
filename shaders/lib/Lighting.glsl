
float safe_pow(float base, float exp) {
    return pow(clamp(base, 0.0, 1.0), exp);
}

float remap_sky_light_level(float raw_light){
    return 0.4 * safe_pow(raw_light, 1.0);
}
float remap_block_light_level(float raw_light){
    return 1.0 * safe_pow(raw_light, 1.9);
}


float process_sky_lighting(){
    float sun_angle_global= (sunAngle < 0.25 ? sunAngle : (sunAngle < 0.5) ? 0.5 - sunAngle : 0.0) * 4 * SUN_BRIGHTNESS;

    float sky_light_level = clamp(sun_angle_global, MINIMUM_SKY_BRIGHTNESS, 1.0);
    return sky_light_level;
}



float process_lighting(vec2 screen_sample, vec2 texturing_uv, vec3 view_normal, vec2 lightmap, float raw_depth, int material){

    if (material == SKY){
        return process_sky_lighting();
    }

    float sun_angle_global= (sunAngle < 0.25 ? sunAngle : (sunAngle < 0.5) ? 0.5 - sunAngle : 0.0) * 4;
    float sun_angle_normals = max(dot(view_normal, normalize(sunPosition)), 0.0);

    vec3 screen_pos = vec3(screen_sample.x, screen_sample.y, raw_depth);
    vec3 shadow = get_shadow_box_blur(screen_pos, texturing_uv, view_normal);

    float sun_light = min(sun_angle_normals, sun_angle_global) * shadow.x;
    float lightmap_block = remap_block_light_level(lightmap.r);
    float lightmap_sky = remap_sky_light_level(lightmap.g);  


    float light_color = lightmap_block + lightmap_sky + sun_light + AMBIENT_LIGHT;

    return clamp(light_color, 0.0, 1.0);
}



float get_contrast_adjustment(){
    vec2 perceptual_brightness = vec2(eyeBrightnessSmooth) / 240.0;
    float perceptual_b_block = perceptual_brightness.x;
    float perceptual_b_sky = perceptual_brightness.y;

    float weight = clamp(1.0 - perceptual_b_sky, 0.0, 1.0);
    float adjusted_block = perceptual_b_block * weight;
    float contrast_adjustment = (adjusted_block + perceptual_b_sky) * CONTRAST;

    return contrast_adjustment;
}
