#version 120

varying vec2 TexCoords;

uniform sampler2D colortex2; // base_contours
uniform sampler2D colortex3; // UV displacement 1
uniform sampler2D colortex4; // UV displacement 2
uniform sampler2D colortex5; // UV displacement 3

uniform sampler2D depthtex0;

uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
vec3 forward_facing_vector = vec3(0.0, 0.0, 1.0);


const float max_offset = 0.0013;
const float ub = 0.7;
const float cs = 0.5;

vec2 decodeDisplacement(vec2 encoded) {
    return vec2(
        (encoded.r - 0.5) * 2.0 * max_offset,
        (encoded.g - 0.5) * 2.0 * max_offset
    );
}

float linearizeDepth(float z) {
    float ndc = z * 2.0 - 1.0;
    return (2.0 * near * far) / (far + near - ndc * (far - near));
}

void main() {
    // Sample and decode each displacement map
    float fragment_depth_raw = texture2D(depthtex0, TexCoords).r;
    float fragment_depth = linearizeDepth(fragment_depth_raw);   
    float depth_scale = 1.0 - clamp((fragment_depth - near) / (far - near), 0.0, 1.0);
    depth_scale = depth_scale * depth_scale;


    vec2 disp1 = decodeDisplacement(texture2D(colortex3, TexCoords).rg) * depth_scale;
    vec2 disp2 = decodeDisplacement(texture2D(colortex4, TexCoords).rg) * depth_scale;
    vec2 disp3 = decodeDisplacement(texture2D(colortex5, TexCoords).rg) * depth_scale;

    // Displaced UVs
    vec2 uv1 = clamp(TexCoords + disp1, 0.0, 1.0);
    vec2 uv2 = clamp(TexCoords + disp2, 0.0, 1.0);
    vec2 uv3 = clamp(TexCoords + disp3, 0.0, 1.0);

    // Sample contour texture at displaced locations
    float contour_1 = 1.0 - texture2D(colortex2, uv1).r;
    float contour_2 = 1.0 - texture2D(colortex2, uv2).r;
    float contour_3 = 1.0 - texture2D(colortex2, uv3).r;

    float ca_1 = 1.0 * (1.0 - cs);
    float ct_1 = 1.0 - ub * ca_1 * contour_1;

    float ca_2 = ct_1 * (1.0 - cs);
    float ct_2 = ct_1 - ub * ca_2 * contour_2;

    float ca_3 = ct_2 * (1.0 - cs);
    float ct_3 = ct_2 - ub * ca_3 * contour_3;

    /* RENDERTARGETS:9 */
    gl_FragData[0] = vec4(vec3(ct_3), 1.0);
}
