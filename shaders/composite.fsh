#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"

varying vec2 TexCoords;

vec3 get_clip_space_normal(vec2 uv){
    return normalize(texture2D(colortex1, uv).rgb * 2.0 - 1.0);
}


float GetShadow(float depth) {
    vec3 ClipSpace = vec3(TexCoords, depth) * 2.0 - 1.0;
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0);
    vec3 View = ViewW.xyz / ViewW.w;
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    vec3 SampleCoords = ShadowSpace.xyz * 0.5 + 0.5;
    return step(SampleCoords.z - 0.001, texture2D(shadowtex0, SampleCoords.xy).r);
}

void main() {
    vec2 texelSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    
    //CONTOUR DETECTION

    //normal based contour detection
    vec3 fragment_normal = get_clip_space_normal(TexCoords);
    vec3 n_left     = get_clip_space_normal(TexCoords + vec2(-texelSize.x, 0.0));
    vec3 n_right    = get_clip_space_normal(TexCoords + vec2(texelSize.x, 0.0));
    vec3 n_up       = get_clip_space_normal(TexCoords + vec2(0.0, texelSize.y));
    vec3 n_down     = get_clip_space_normal(TexCoords + vec2(0.0, -texelSize.y));

    float dx = length(fragment_normal - n_right) + length(fragment_normal - n_left);
    float dy = length(fragment_normal - n_up) + length(fragment_normal - n_down);
    float normal_response = (dx + dy) > 0.01 ? 1.0 : 0.0;

    //depth based contour detection
    float fragment_depth_raw = texture2D(depthtex0, TexCoords).r;
    float fragment_depth = linearize_depth(fragment_depth_raw);
    float dL = linearize_depth(texture2D(depthtex0, TexCoords + vec2(-texelSize.x, 0.0)).r);
    float dR = linearize_depth(texture2D(depthtex0, TexCoords + vec2( texelSize.x, 0.0)).r);
    float dU = linearize_depth(texture2D(depthtex0, TexCoords + vec2(0.0,  texelSize.y)).r);
    float dD = linearize_depth(texture2D(depthtex0, TexCoords + vec2(0.0, -texelSize.y)).r);

    float residual_x = abs(fragment_depth - 0.5 * (dL + dR));
    float residual_y = abs(fragment_depth - 0.5 * (dU + dD));

    float linearity_eps = 0.003;

    float relative_residual = (residual_x + residual_y) / fragment_depth;
    float depth_response = relative_residual > linearity_eps ? 1.0 : 0.0;

    float edge = (normal_response + depth_response) > 0.0 ? 0.0 : 1.0;
    
    //SHADOW MAP CONSTRUCTION
    vec3 shadow = fragment_depth_raw < 1.0 ? vec3(GetShadow(fragment_depth_raw)) : vec3(1.0);

    /* RENDERTARGETS:7,8 */
    gl_FragData[0] = vec4(vec3(edge), 1.0);
    gl_FragData[1] = vec4(shadow, 1.0);

}