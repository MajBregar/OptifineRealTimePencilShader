#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"

varying vec2 TexCoords;

#define CONTOUR_DETECTION_THRESHOLD_NORMALS 0.9999
#define CONTOUR_DETECTION_THRESHOLD_COPLANAR 0.0001

float detect_contour_and_inflate(vec2 uv){
    vec3 center_normal = texture2D(colortex1, uv).rgb;
    vec3 center_position = texture2D(colortex10, uv).rgb;

    for (int x = -CONTOUR_DETECTION_KERNEL_SIZE; x <= CONTOUR_DETECTION_KERNEL_SIZE; x++){
        for (int y = -CONTOUR_DETECTION_KERNEL_SIZE; y <= CONTOUR_DETECTION_KERNEL_SIZE; y++){
            if (x == 0 && y == 0) continue;

            vec2 sample_uv = uv + vec2(x * texelSize.x, y * texelSize.y);
            
            vec3 neighbour_normal = texture2D(colortex1, sample_uv).rgb;
            vec3 neighbour_position    = texture2D(colortex10, sample_uv).rgb;

            float normal_similarity = dot(center_normal, neighbour_normal);
            vec3 pos_diff_normal = normalize(neighbour_position - center_position);

            float coplanarity = abs(dot(center_normal, pos_diff_normal));

            if (normal_similarity < CONTOUR_DETECTION_THRESHOLD_NORMALS || coplanarity > CONTOUR_DETECTION_THRESHOLD_COPLANAR) return 0.0;
        }
    }
    return 1.0;
}

void main() {
    
    float edge = detect_contour_and_inflate(TexCoords);

    /* RENDERTARGETS:7 */
    gl_FragData[0] = vec4(vec3(edge), 1.0);
}
