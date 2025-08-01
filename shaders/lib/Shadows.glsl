

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

vec3 distortShadowClipPos(vec3 shadowClipPos){
  float distortionFactor = length(shadowClipPos.xy); // distance from the player in shadow clip space
  distortionFactor += 0.1;

  shadowClipPos.xy /= distortionFactor;
  shadowClipPos.z *= 0.5; // increases shadow distance on the Z axis, which helps when the sun is very low in the sky
  return shadowClipPos;
}


vec3 getShadow(vec3 shadowScreenPos){
  float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r); // sample the shadow map containing everything

  /*
  note that a value of 1.0 means 100% of sunlight is getting through
  not that there is 100% shadowing
  */

  if(transparentShadow == 1.0){
    /*
    since this shadow map contains everything,
    there is no shadow at all, so we return full sunlight
    */
    return vec3(1.0);
  }

  float opaqueShadow = step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r); // sample the shadow map containing only opaque stuff

  if(opaqueShadow == 0.0){
    // there is a shadow cast by something opaque, so we return no sunlight
    return vec3(0.0);
  }

  // contains the color and alpha (transparency) of the thing casting a shadow
  vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);


  /*
  we use 1 - the alpha to get how much light is let through
  and multiply that light by the color of the caster
  */
  return shadowColor.rgb * (1.0 - shadowColor.a);
}

vec4 getNoise(vec2 coord){
  ivec2 screenCoord = ivec2(coord * vec2(viewWidth, viewHeight));
  ivec2 noiseCoord = screenCoord % noiseTextureResolution;
  return texelFetch(noisetex, noiseCoord, 0);
}

vec4 get_shadow_map_clip_pos(vec2 tex_uv, float depth){
    vec3 NDCPos = vec3(tex_uv, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;

    return shadowProjection * vec4(shadowViewPos, 1.0);
}


vec3 getSoftShadow(vec2 uv, vec4 shadowClipPos){
  const float range = SHADOW_SOFTNESS / 2.0;
  const float increment = range / SHADOW_QUALITY;

  float noise = getNoise(uv).r;

  float theta = noise * radians(360.0);
  float cosTheta = cos(theta);
  float sinTheta = sin(theta);

  mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta);

  vec3 shadowAccum = vec3(0.0);
  int samples = 0;

  for(float x = -range; x <= range; x += increment){
    for (float y = -range; y <= range; y+= increment){
      vec2 offset = rotation * vec2(x, y) / shadowMapResolution;
      vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0); // add offset
      offsetShadowClipPos.z -= 0.00001; // apply bias
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
      vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
      shadowAccum += getShadow(shadowScreenPos); // take shadow sample
      samples++;
    }
  }

  return shadowAccum / float(samples); // divide sum by count, getting average shadow
}

float remap_sky_light_level(float raw_light){

    float x = 0.0;
    return 1.0 * pow(raw_light, 1.0) * (1.0 - 2 * x) + x;
}

float remap_block_light_level(float raw_light){
    return 1.1 * pow(raw_light, 2.2);
}

float remap_sun_light_level(float raw_light){
    return 1.0 * pow(raw_light, 1.0);
}



vec2 get_lightmap_light(vec2 uv){
  vec2 lightmap_levels = texture2D(colortex3, uv).rg;
  return vec2(remap_sky_light_level(lightmap_levels.g), remap_block_light_level(lightmap_levels.r));
}
