
float remap_sky_light_level(float raw_light){
    return 1.0 * pow(raw_light, 1.0);
}
float remap_block_light_level(float raw_light){
    return 1.1 * pow(raw_light, 2.2);
}

float remap_sun_light_level(float raw_light){
    return 1.0 * pow(raw_light, 1.0);
}

float process_lighting(vec3 fragcoords, vec2 texturing_uv, vec3 view_normal, vec2 lightmap){

    float sun_angle_block = max(dot(view_normal, normalize(sunPosition)), 0.0);
    float sun_brightness = 1.3;
    float sun_angle_world = max(dot(world_y_normal, normalize(mat3(gbufferModelViewInverse) * sunPosition)), 0.0) * sun_brightness;

    vec3 shadow = get_shadow_box_blur(fragcoords, texturing_uv);

    float sun_light = remap_sun_light_level(min(sun_angle_block, sun_angle_world) * clamp(shadow.x, 0.0, 1.0));

    float lightmap_block = lightmap.r;
    float lightmap_sky = lightmap.g;

    float light_color = clamp(lightmap_sky * sun_angle_world + lightmap_block + sun_light + AMBIENT_LIGHT, 0.0, 1.0);

    return light_color;
}


float process_sky_lighting(){

    float sun_brightness = 1.3;
    float sun_angle_world = max(dot(world_y_normal, normalize(mat3(gbufferModelViewInverse) * sunPosition)), 0.0) * sun_brightness;

    float sky_light_level = clamp(sun_angle_world * 1.4, 0.05, 1.0);

    return sky_light_level;
}