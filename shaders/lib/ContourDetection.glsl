
vec3 default_contour_detection(vec2 center_uv, int center_material_id){

    vec3 center_model_normal = texture2D(MODEL_NORMALS, center_uv).rgb;
    vec3 center_world_position = texture2D(MODEL_POSITIONS, center_uv).rgb + cameraPosition;

    for (int x = -1; x <= 1; x++){
        for (int y = -1; y <= 1; y++){
            if (x == 0 && y == 0) continue;
            vec2 neighbour_sample_uv = center_uv + vec2(x * texelSize.x, y * texelSize.y);
            
            //MATERIAL DIFFERENCE CHECK
            int neighbour_material_id = get_id(neighbour_sample_uv);
            if (center_material_id != neighbour_material_id) return vec3(1.0, neighbour_sample_uv);

            //NORMAL DIFFERENCE CHECK
            vec3 neighbour_model_normal = texture2D(MODEL_NORMALS, neighbour_sample_uv).rgb;
            if (dot(center_model_normal, neighbour_model_normal) < CONTOUR_DETECTION_NORMAL_SIMILARITY_THR) return vec3(1.0, neighbour_sample_uv);        

            //PLANE DIFFERENCE CHECK
            vec3 neighbour_world_position = texture2D(MODEL_POSITIONS, neighbour_sample_uv).rgb + cameraPosition;
            float distance_to_plane = abs(dot(center_model_normal,  neighbour_world_position - center_world_position));
            if (distance_to_plane > CONTOUR_DETECTION_PLANE_DIST_THR) return vec3(1.0, neighbour_sample_uv);
        }
    }
    return vec3(0.0);
}


vec3 detect_contour(vec2 center_uv){

    int center_material_id = get_id(center_uv);

    switch (center_material_id) {
        default: return default_contour_detection(center_uv, center_material_id);
    }
}
