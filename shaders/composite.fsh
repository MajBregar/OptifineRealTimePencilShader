#version 120

varying vec2 TexCoords;

uniform sampler2D colortex1;    //block view normals
uniform sampler2D depthtex0;    //depth texture

uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
vec3 forward_facing_vector = vec3(0.0, 0.0, 1.0);

float linearizeDepth(float z) {
    float ndc = z * 2.0 - 1.0;
    return (2.0 * near * far) / (far + near - ndc * (far - near));
}

void main() {
    vec2 texelSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    
    //CONTOUR DETECTION

    //normal based contour detection
    vec3 fragment_normal = texture2D(colortex1, TexCoords).rgb;
    vec3 n_left     = texture2D(colortex1, TexCoords + vec2(-texelSize.x, 0.0)).rgb;
    vec3 n_right    = texture2D(colortex1, TexCoords + vec2(texelSize.x, 0.0)).rgb;
    vec3 n_up       = texture2D(colortex1, TexCoords + vec2(0.0, texelSize.y)).rgb;
    vec3 n_down     = texture2D(colortex1, TexCoords + vec2(0.0, -texelSize.y)).rgb;

    float dx = length(fragment_normal - n_right) + length(fragment_normal - n_left);
    float dy = length(fragment_normal - n_up) + length(fragment_normal - n_down);
    float normal_response = (dx + dy) > 0.01 ? 1.0 : 0.0;

    //depth based contour detection
    float fragment_depth_raw = texture2D(depthtex0, TexCoords).r;
    float fragment_depth = linearizeDepth(fragment_depth_raw);
    float dL = linearizeDepth(texture2D(depthtex0, TexCoords + vec2(-texelSize.x, 0.0)).r);
    float dR = linearizeDepth(texture2D(depthtex0, TexCoords + vec2( texelSize.x, 0.0)).r);
    float dU = linearizeDepth(texture2D(depthtex0, TexCoords + vec2(0.0,  texelSize.y)).r);
    float dD = linearizeDepth(texture2D(depthtex0, TexCoords + vec2(0.0, -texelSize.y)).r);

    float residual_x = abs(fragment_depth - 0.5 * (dL + dR));
    float residual_y = abs(fragment_depth - 0.5 * (dU + dD));

    float linearity_eps = 0.003;

    float relative_residual = (residual_x + residual_y) / fragment_depth;
    float depth_response = relative_residual > linearity_eps ? 1.0 : 0.0;

    float edge = (normal_response + depth_response) > 0.0 ? 0.0 : 1.0;

    /* RENDERTARGETS:7 */
    gl_FragData[0] = vec4(vec3(edge), 1.0);
}