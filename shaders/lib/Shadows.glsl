

vec3 distort_shadow_clip_pos(vec3 shadow_ndc) {
    float len_to_edge = length(shadow_ndc.xy);
    float distortion = len_to_edge * SHADOW_BIAS + (1.0 - SHADOW_BIAS);

    shadow_ndc.xy /= distortion;
    shadow_ndc.z *= SHADOW_Z_COMPRESSION; 
    return shadow_ndc;
}

vec4 get_shadow_map_clip_hom_position_biased(vec3 fragcords, vec3 view_normal){
    vec3 fragment_screen_pos = vec3(fragcords.xy / vec2(viewWidth, viewHeight), fragcords.z);
    vec3 fragment_view_pos = screen_to_view_space(fragment_screen_pos);
    vec3 fragment_player_feet_pos = view_to_player_feet_space(fragment_view_pos);


    vec3 player_space_normal = normalize(view_to_player_feet_space(view_normal));

    float sun_angle = 1.0 - abs(dot(view_normal, normalize(sunPosition)));
    float view_angle = 1.0 - abs(dot(view_normal, normalize(fragment_view_pos)));
    float dist_squared = dot(fragment_player_feet_pos, fragment_player_feet_pos);

    float distance_bias = 0.05 * SHADOW_SOFTNESS + 0.0001 * dist_squared; //hardcoded
    vec3 displacement_bias = player_space_normal * distance_bias;

    vec3 displaced_shadow_sample_feet_pos = fragment_player_feet_pos + displacement_bias;

    vec4 shadow_view_pos_homogenous = (shadowModelView * vec4(displaced_shadow_sample_feet_pos, 1.0));
    vec4 shadow_clip_homogenous = shadowProjection * shadow_view_pos_homogenous;
    return shadow_clip_homogenous;
}


vec3 get_shadow(vec3 shadow_map_screen){
  float shadow_all = step(shadow_map_screen.z, texture2D(SHADOWS_OPAQUE, shadow_map_screen.xy).r);

  if(shadow_all == 1.0) return vec3(1.0); //no shadow

  float shadow_no_transparent = step(shadow_map_screen.z, texture2D(SHADOWS_TRANSPARANT, shadow_map_screen.xy).r);

  if(shadow_no_transparent == 0.0) return vec3(0.0); //normal shadow

  vec4 shadowColor = texture2D(SHADOW_COLOR, shadow_map_screen.xy);
  return vec3(1.0) * (1.0 - shadowColor.a); //disabled colored shadows for now
}


vec3 get_shadow_box_blur(vec3 fragcords, vec2 noise_sample_uv, vec3 view_normal){

  vec4 center_shadow_map_clip_pos = get_shadow_map_clip_hom_position_biased(fragcords, view_normal);

  float noise = texture2D(noisetex, noise_sample_uv * SHADOW_NOISE_REPEAT_MULTIPLIER).r; 
  float theta = noise * radians(360.0);
  float cosTheta = cos(theta);
  float sinTheta = sin(theta);
  mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta);

  vec3 shadow_sum = vec3(0.0);
  int samples = 0;

  for (float x = -BOX_BLUR_RANGE; x <= BOX_BLUR_RANGE; x += BOX_BLUR_INCREMENT) {
    for (float y = -BOX_BLUR_RANGE; y <= BOX_BLUR_RANGE; y += BOX_BLUR_INCREMENT) {
      if (x*x + y*y > BOX_BLUR_RANGE*BOX_BLUR_RANGE) continue;

      vec2 offset = rotation * vec2(x, y) / shadowMapResolution;
      vec4 shadow_clip = center_shadow_map_clip_pos + vec4(offset, 0.0, 0.0);
      vec3 shadow_ndc = shadow_clip.xyz / shadow_clip.w;
      vec3 dsp = distort_shadow_clip_pos(shadow_ndc) * 0.5 + 0.5;

      shadow_sum += get_shadow(dsp);
      samples++;
    }
  }
  
  return shadow_sum / float(samples);
}
