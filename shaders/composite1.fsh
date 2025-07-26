#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"

varying vec2 TexCoords;

#define KERNEL_THR 13
#define KERNEL_DIM CONTOUR_DETECTION_KERNEL_SIZE * 2 + 1

vec3 inflate_and_filter_contour(vec2 uv){
    int detected_count = 0;
    float closest_falloff = 0.0;
    float min_dist = float(KERNEL_DIM);

    for (int x = -CONTOUR_DETECTION_KERNEL_SIZE; x <= CONTOUR_DETECTION_KERNEL_SIZE; x++){
        for (int y = -CONTOUR_DETECTION_KERNEL_SIZE; y <= CONTOUR_DETECTION_KERNEL_SIZE; y++){
            vec2 sample_uv = uv + vec2(x * texelSize.x, y * texelSize.y);
            vec4 neighbour_contour = texture2D(colortex7, sample_uv);

            if (neighbour_contour.r == 1.0) {
                detected_count++;
                closest_falloff = max(closest_falloff, neighbour_contour.a);
                min_dist = min(min_dist, abs(float(x)) + abs(float(y)));
            }
        }
    }

    if (detected_count > KERNEL_THR) {
        return vec3(1.0, min_dist, closest_falloff);
    }
    return vec3(0.0, 0.0, 1.0);
}

void main() {
    
    vec3 contour = inflate_and_filter_contour(TexCoords);

    float out_color = 0.0;
    if (contour.x == 1.0){
        float color_falloff = pow(contour.z, CONTOUR_COLOR_FALLOFF);
        float thickness_falloff = clamp(pow(1.0 - contour.y / float(CONTOUR_DETECTION_KERNEL_SIZE), CONTOUR_THICKNESS_FALLOFF), 0.0, 1.0);

        out_color = color_falloff * thickness_falloff;
    }

    /* RENDERTARGETS:4 */
    gl_FragData[0] = vec4(vec3(out_color), contour.z);
}
