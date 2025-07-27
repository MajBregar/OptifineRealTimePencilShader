#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"

varying vec2 TexCoords;

#define CONTOUR_DETECTION_THRESHOLD_NORMALS 0.9
#define CONTOUR_DETECTION_THRESHOLD_COPLANAR 0.0001

float detect_contour(vec2 uv){
    vec3 center_normal = texture2D(colortex1, uv).rgb;
    vec3 center_position = texture2D(colortex10, uv).rgb;
    
    for (int x = -1; x <= 1; x++){
        for (int y = -1; y <= 1; y++){
            if (x == 0 && y == 0) continue;

            vec2 sample_uv = uv + vec2(x * texelSize.x, y * texelSize.y);

            //normal based cd
            vec3 neighbour_normal = texture2D(colortex1, sample_uv).rgb;
            float normal_similarity = dot(center_normal, neighbour_normal);

            if (normal_similarity < CONTOUR_DETECTION_THRESHOLD_NORMALS) return 1.0;        

            //positional based cd
            vec3 neighbour_position = texture2D(colortex10, sample_uv).rgb;
            vec3 pos_diff_normal = normalize(neighbour_position - center_position);
            float coplanarity = abs(dot(center_normal, pos_diff_normal));

            if (coplanarity > CONTOUR_DETECTION_THRESHOLD_COPLANAR) return 1.0;
        }
    }
    return 0.0;
}

void main() {
    
    float edge = detect_contour(TexCoords);
    float fragment_depth_raw = texture2D(depthtex0, TexCoords).r;
    float view_depth_falloff = 1.0 - linearize_to_view_dist(fragment_depth_raw);
    


    /* RENDERTARGETS:7 */
    gl_FragData[0] = vec4(vec3(edge), view_depth_falloff);
}
