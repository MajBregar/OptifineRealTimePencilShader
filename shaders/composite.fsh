#version 430
#define COMPOSITE
#define FRAGMENT_SHADER
#include "lib/Inc.glsl"

varying vec2 TexCoords;




void main() {
    float center_view_dist_depth = normalize_to_view_dist(texture2D(DEPTH_BUFFER_ALL, TexCoords).r);

    vec3 contour_data = detect_contour(TexCoords);

    vec4 edge_data_output = vec4(0.0, 0.0, 0.0, center_view_dist_depth);
    if (contour_data.r == 1.0) {
        float neighbour_view_dist_depth = normalize_to_view_dist(texture2D(DEPTH_BUFFER_ALL, contour_data.yz).r);
        edge_data_output = vec4(1.0, 1.0, 1.0, min(center_view_dist_depth, neighbour_view_dist_depth));
    }

    /* RENDERTARGETS:4 */
    gl_FragData[0] = edge_data_output;
}