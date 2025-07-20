#version 120

varying vec2 TexCoords;

uniform sampler2D colortex2; // base contour map
uniform sampler2D colortex3; // UV displacement 1
uniform sampler2D colortex4; // UV displacement 2
uniform sampler2D colortex5; // UV displacement 3

const float max_offset_u = 3.5 / 2560.0;
const float max_offset_v = 3.5 / 1440.0;

const float ub = 0.7;
const float cs = 0.5;

vec2 decodeDisplacement(vec2 encoded) {
    return vec2(
        (encoded.r - 0.5) * 2.0 * max_offset_u,
        (encoded.g - 0.5) * 2.0 * max_offset_v
    );
}

void main() {
    // Sample and decode each displacement map
    vec2 disp1 = decodeDisplacement(texture2D(colortex3, TexCoords).rg);
    vec2 disp2 = decodeDisplacement(texture2D(colortex4, TexCoords).rg);
    vec2 disp3 = decodeDisplacement(texture2D(colortex5, TexCoords).rg);

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

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(vec3(ct_3), 1.0);
}
