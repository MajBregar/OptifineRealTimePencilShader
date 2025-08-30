

vec3 distort_shadow_clip_pos(vec3 shadow_clip) {
    float len_to_edge = length(shadow_clip.xy);
    float distortion = len_to_edge + SHADOW_DISTORTION_BIAS;

    shadow_clip.xy /= distortion;
    shadow_clip.z *= SHADOW_Z_COMPRESSION; 
    return shadow_clip;
}

vec4 get_shadow_map_clip_hom_position_biased(vec3 fragment_screen_pos, vec3 view_normal){
    vec3 fragment_view_pos = screen_to_view_space(fragment_screen_pos);
    vec3 fragment_player_feet_pos = view_to_player_feet_space(fragment_view_pos);


    vec3 player_space_normal = normalize(view_to_player_feet_space(view_normal));

    float dist_squared = dot(fragment_player_feet_pos, fragment_player_feet_pos);

    float distance_bias = 0.05 * SHADOW_SOFTNESS + 0.0001 * dist_squared; //hardcoded
    vec3 displacement_bias = player_space_normal * distance_bias;

    vec3 displaced_shadow_sample_feet_pos = fragment_player_feet_pos + displacement_bias;

    vec4 shadow_view_pos_homogenous = (shadowModelView * vec4(displaced_shadow_sample_feet_pos, 1.0));
    vec4 shadow_clip_homogenous = shadowProjection * shadow_view_pos_homogenous;
    return shadow_clip_homogenous;
}


vec3 get_shadow(vec3 screen_pos){

  float shadow_map_depth1 = texture2D(SHADOWS_OPAQUE, screen_pos.xy).r;

  //if shadow map sample 1 is further to sun than sample => no shadow (hit front face)
  if(shadow_map_depth1 >= screen_pos.z) return vec3(1.0);

  //here we already know we have a shadow hit on all geometry

  float shadow_map_depth2 = texture2D(SHADOWS_TRANSPARANT, screen_pos.xy).r;

  //if shadow map sample 2 is closer to sun than sample => we hit opaque geometry (full shadow)
  if(shadow_map_depth2 < screen_pos.z) return vec3(0.0);

  //if we didnt hit opaque geometry then that means we hit transparent geometry - calculate shadow value from color transparency
  vec4 shadowColor = texture2D(SHADOW_COLOR, screen_pos.xy);
  return vec3(1.0) * (1.0 - shadowColor.a);
}


vec3 get_shadow_box_blur(vec3 screen_pos, vec2 noise_sample_uv, vec3 view_normal){

  vec4 center_shadow_map_clip_pos = get_shadow_map_clip_hom_position_biased(screen_pos, view_normal);


  ivec2 screen_coord = ivec2(screen_pos.xy * vec2(viewWidth, viewHeight));
  ivec2 noise_coord = screen_coord % 128;

  float noise = texelFetch(noisetex, noise_coord, 0).r; 
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

      shadow_clip.xyz = distort_shadow_clip_pos(shadow_clip.xyz);

      vec3 shadow_clip_div = shadow_clip.xyz / shadow_clip.w;

      shadow_sum += get_shadow(shadow_clip_div * 0.5 + 0.5);
      samples++;
    }
  }
  
  return shadow_sum / float(samples);
}
