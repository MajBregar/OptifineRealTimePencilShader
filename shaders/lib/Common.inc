
const int shadowMapResolution = 2048;
const int noiseTextureResolution = 128;
const float sunPathRotation = -45.0;

const vec3 forward_facing_vector = vec3(0.0, 0.0, 1.0);

float linearize_depth(float depth) {
    float ndc = depth * 2.0 - 1.0;
    return (2.0 * near * far) / (far + near - ndc * (far - near));
}

vec3 get_view_space_normal(vec2 uv){
    return normalize(texture2D(colortex1, uv).rgb * 2.0 - 1.0);
}

bool is_sky(vec2 uv) {
    float depth = texture2D(depthtex1, uv).r;
    return depth == 1.0;
}

vec2 distort_position(vec2 position){
    float CenterDistance = length(position);
    float DistortionFactor = mix(1.0, CenterDistance, 0.9);
    return position / DistortionFactor;
}

float Visibility(sampler2D ShadowMap, vec3 SampleCoords) {
    return step(SampleCoords.z - 0.001, texture2D(ShadowMap, SampleCoords.xy).r);
}

vec3 TransparentShadow(vec3 SampleCoords){
    float ShadowVisibility0 = Visibility(shadowtex0, SampleCoords);
    float ShadowVisibility1 = Visibility(shadowtex1, SampleCoords);
    vec4 ShadowColor0 = texture2D(shadowcolor0, SampleCoords.xy);
    //vec3 TransmittedColor = ShadowColor0.rgb * (1.0 - ShadowColor0.a); // turns on colored shadows
    vec3 TransmittedColor = vec3(1.0) * (1.0 - ShadowColor0.a);
    return mix(TransmittedColor * ShadowVisibility1, vec3(1.0f), ShadowVisibility0);
}


vec3 get_shadow(vec2 sample_uv, float depth) {
    int ShadowSamplesPerSize = 2 * SHADOW_SAMPLES + 1;
    int TotalSamples = ShadowSamplesPerSize * ShadowSamplesPerSize;

    vec3 ClipSpace = vec3(sample_uv, depth) * 2.0 - 1.0;
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0f);
    vec3 View = ViewW.xyz / ViewW.w;
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0f);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    ShadowSpace.xy = distort_position(ShadowSpace.xy);
    vec3 SampleCoords = ShadowSpace.xyz * 0.5f + 0.5f;
    float RandomAngle = texture2D(noisetex, sample_uv * 20.0f).r * 100.0f;
    float cosTheta = cos(RandomAngle);
	float sinTheta = sin(RandomAngle);
    mat2 Rotation =  mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution; // We can move our division by the shadow map resolution here for a small speedup
    vec3 ShadowAccum = vec3(0.0f);
    for(int x = -SHADOW_SAMPLES; x <= SHADOW_SAMPLES; x++){
        for(int y = -SHADOW_SAMPLES; y <= SHADOW_SAMPLES; y++){
            vec2 Offset = Rotation * vec2(x, y);
            vec3 CurrentSampleCoordinate = vec3(SampleCoords.xy + Offset, SampleCoords.z);
            ShadowAccum += TransparentShadow(CurrentSampleCoordinate);
        }
    }
    ShadowAccum /= TotalSamples;
    return ShadowAccum;
}