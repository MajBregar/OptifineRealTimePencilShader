#version 430
#define COMPOSITE
#define FRAGMENT_SHADER
#include "../lib/Inc.glsl"

varying vec2 TexCoords;

#define CONTOUR_DETECTION_THRESHOLD_NORMALS 0.999
#define CONTOUR_DETECTION_THRESHOLD_COPLANAR 0.001

vec3 hand_contour_detection(vec2 uv, vec3 center_world_normal) {

    vec3 center_view_normal = normalize(mat3(gbufferModelView) * center_world_normal);

    for (int x = -1; x <= 1; x++){
        for (int y = -1; y <= 1; y++){
            if (x == 0 && y == 0) continue;

            vec2 sample_uv = uv + vec2(x * texelSize.x, y * texelSize.y);

            //normal based cd
            vec3 neighbour_view_normal = normalize(mat3(gbufferModelView) * texture2D(MODEL_NORMALS, sample_uv).rgb);

            float normal_similarity = dot(center_view_normal, neighbour_view_normal);

            if (normal_similarity < CONTOUR_DETECTION_THRESHOLD_NORMALS) return vec3(1.0, sample_uv);   

        }
    }
    return vec3(0.0);
}


vec3 detect_contour(vec2 uv){

    vec3 center_world_normal = texture2D(MODEL_NORMALS, uv).rgb;
    int center_material = get_id(TexCoords);

    if (center_material >= HAND_HOLD_IDS) return hand_contour_detection(uv, center_world_normal);

    vec3 center_world_position = texture2D(MODEL_POSITIONS, uv).rgb + cameraPosition;

    
    for (int x = -1; x <= 1; x++){
        for (int y = -1; y <= 1; y++){
            if (x == 0 && y == 0) continue;

            vec2 sample_uv = uv + vec2(x * texelSize.x, y * texelSize.y);
            
            int neighbour_material = get_id(sample_uv);
            if (center_material != neighbour_material) return vec3(1.0, sample_uv);

            if (allowed_self_contour_detection(center_material) == false) continue; 

            //normal based cd
            vec3 neighbour_world_normal = texture2D(MODEL_NORMALS, sample_uv).rgb;
            if (neighbour_world_normal.x > 1.0) continue;

            float normal_similarity = dot(center_world_normal, neighbour_world_normal);

            if (normal_similarity < CONTOUR_DETECTION_THRESHOLD_NORMALS) return vec3(1.0, sample_uv);        

            //positional based cd
            vec3 neighbour_world_position = texture2D(MODEL_POSITIONS, sample_uv).rgb + cameraPosition;
            vec3 pos_diff_normal = normalize(neighbour_world_position - center_world_position);

            float coplanarity = abs(dot(center_world_normal, pos_diff_normal));

            if (coplanarity > CONTOUR_DETECTION_THRESHOLD_COPLANAR) return vec3(1.0, sample_uv);
        }
    }
    return vec3(0.0);
}

void main() {
    float center_view_dist_depth = normalize_to_view_dist(texture2D(DEPTH_BUFFER_ALL, TexCoords).r);

    vec3 edge = detect_contour(TexCoords);

    vec4 edge_data_output = vec4(0.0, 0.0, 0.0, center_view_dist_depth);
    if (edge.r == 1.0) {
        float neighbour_view_dist_depth = normalize_to_view_dist(texture2D(DEPTH_BUFFER_ALL, edge.yz).r);
        edge_data_output = vec4(1.0, 1.0, 1.0, min(center_view_dist_depth, neighbour_view_dist_depth));
    }

    /* RENDERTARGETS:4 */
    gl_FragData[0] = edge_data_output;
}