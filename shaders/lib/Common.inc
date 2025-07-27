
/*
const int colortex1Format = RGB32F;
const int colortex10Format = RGB32F;
const int colortex11Format = RGB32F;
const int colortex8Format = RGBA16;
*/


const int shadowMapResolution = 2048;
const int noiseTextureResolution = 128;
const float sunPathRotation = 45.0;


const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;

const vec3 forward_facing_vector = vec3(0.0, 0.0, 1.0);
vec2 texelSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);


float linearize_depth(float d)
{
  float z_n = d * 2.0 - 1.0;  // convert [0,1]→[-1,1] NDC
  float z_eye = (2.0 * near * far) / (far + near - z_n * (far - near));
  return z_eye;
}

float linearize_to_view_dist(float depth){
  return clamp(linearize_depth(depth) / min(far, float(CONTOUR_VIEW_DISTANCE)), 0.0, 1.0);
}

bool is_sky(vec2 uv) {
    float depth = texture2D(depthtex1, uv).r;
    return depth == 1.0;
}

float pencil_blend_function(float ct, float cs, float local_UB, float local_UW, float local_THR) {
    float ca = ct * (1.0 - cs);
    ca = ct >= local_THR ? ca * local_UW : ca;
    return ct - local_UB * ca;
}

vec3 distortShadowClipPos(vec3 shadowClipPos){
  float distortionFactor = length(shadowClipPos.xy); // distance from the player in shadow clip space
  distortionFactor += 0.1;

  shadowClipPos.xy /= distortionFactor;
  shadowClipPos.z *= 0.5; // increases shadow distance on the Z axis, which helps when the sun is very low in the sky
  return shadowClipPos;
}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
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
  const float range = SHADOW_SOFTNESS / 2.0; // how far away from the original position we take our samples from
  const float increment = range / SHADOW_QUALITY; // distance between each sample

  float noise = getNoise(uv).r;

  float theta = noise * radians(360.0); // random angle using noise value
  float cosTheta = cos(theta);
  float sinTheta = sin(theta);

  mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta); // matrix to rotate the offset around the original position by the angle

  vec3 shadowAccum = vec3(0.0); // sum of all shadow samples
  int samples = 0;

  for(float x = -range; x <= range; x += increment){
    for (float y = -range; y <= range; y+= increment){
      vec2 offset = rotation * vec2(x, y) / shadowMapResolution; // offset in the rotated direction by the specified amount. We divide by the resolution so our offset is in terms of pixels
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

