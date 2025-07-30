#version 120
#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

varying vec2 TexCoords;

#define CONTOUR_DETECTION_THRESHOLD_NORMALS 0.999
#define CONTOUR_DETECTION_THRESHOLD_COPLANAR 0.001

vec3 hand_contour_detection(vec2 uv) {

    vec3 center_world_normal = texture2D(colortex1, uv).rgb - 10.0;

    for (int x = -1; x <= 1; x++){
        for (int y = -1; y <= 1; y++){
            if (x == 0 && y == 0) continue;

            vec2 sample_uv = uv + vec2(x * texelSize.x, y * texelSize.y);
            vec3 neighbour_world_normal = texture2D(colortex1, sample_uv).rgb - 10.0;

            float normal_similarity = dot(center_world_normal, neighbour_world_normal);

            if (normal_similarity < CONTOUR_DETECTION_THRESHOLD_NORMALS) return vec3(1.0, sample_uv);     

        }
    }
    return vec3(0.0);
}


vec3 detect_contour(vec2 uv){

    vec3 center_world_normal = texture2D(colortex1, uv).rgb;

    if (center_world_normal.x > 1.0) return hand_contour_detection(uv);

    vec3 center_world_position = texture2D(colortex2, uv).rgb + cameraPosition;
    
    for (int x = -1; x <= 1; x++){
        for (int y = -1; y <= 1; y++){
            if (x == 0 && y == 0) continue;

            vec2 sample_uv = uv + vec2(x * texelSize.x, y * texelSize.y);

            //normal based cd
            vec3 neighbour_world_normal = texture2D(colortex1, sample_uv).rgb;
            float normal_similarity = dot(center_world_normal, neighbour_world_normal);

            if (normal_similarity < CONTOUR_DETECTION_THRESHOLD_NORMALS) return vec3(1.0, sample_uv);        

            //positional based cd
            vec3 neighbour_world_position = texture2D(colortex2, sample_uv).rgb + cameraPosition;
            vec3 pos_diff_normal = normalize(neighbour_world_position - center_world_position);

            float coplanarity = abs(dot(center_world_normal, pos_diff_normal));

            if (coplanarity > CONTOUR_DETECTION_THRESHOLD_COPLANAR) return vec3(1.0, sample_uv);
        }
    }
    return vec3(0.0);
}

void main() {
    
    vec3 edge = detect_contour(TexCoords);

    vec4 edge_data_output = vec4(0.0);
    if (edge.r == 1.0) {
        float fragment_depth_raw = texture2D(depthtex0, TexCoords).r;
        float neighbour_depth_raw = texture2D(depthtex0, edge.gb).r;
        float linear_depth_falloff = 1.0 - linearize_to_view_dist(min(fragment_depth_raw, neighbour_depth_raw));
        edge_data_output = vec4(1.0, 1.0, 1.0, linear_depth_falloff);
    }

    /* RENDERTARGETS:8 */
    gl_FragData[0] = edge_data_output;
}