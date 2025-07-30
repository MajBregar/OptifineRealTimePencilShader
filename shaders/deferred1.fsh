#version 120
#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

varying vec2 TexCoords;

#define KERNEL_THR 13
#define KERNEL_DIM CONTOUR_DETECTION_KERNEL_SIZE * 2 + 1
#define CONTOUR_THICKNESS_STEP 1.0 / CONTOUR_DETECTION_KERNEL_SIZE

vec3 inflate_and_filter_contour(vec2 uv){
    vec4 center_contour = texture2D(colortex4, uv);
    if (center_contour.r == 1.0) return vec3(1.0, 0.0, center_contour.a);

    int detected_count = 0;
    float falloff = 0.0;
    float min_dist = float(KERNEL_DIM);

    for (int x = -CONTOUR_DETECTION_KERNEL_SIZE; x <= CONTOUR_DETECTION_KERNEL_SIZE; x++){
        for (int y = -CONTOUR_DETECTION_KERNEL_SIZE; y <= CONTOUR_DETECTION_KERNEL_SIZE; y++){
            if (x == 0 && y == 0) continue;

            vec2 sample_uv = uv + vec2(x * texelSize.x, y * texelSize.y);
            vec4 neighbour_contour = texture2D(colortex4, sample_uv);

            if (neighbour_contour.r != 1.0) continue;

            detected_count++;
            float dist = abs(float(x)) + abs(float(y));

            if (dist < min_dist){
                min_dist = dist;
                falloff = neighbour_contour.a;
            }                
            
        }
    }

    if (detected_count > KERNEL_THR) return vec3(1.0, min_dist, falloff);
    return vec3(0.0, 0.0, 1.0);
}

void main() {
    
    vec3 contour = inflate_and_filter_contour(TexCoords);

    float out_color = 0.0;
    if (contour.x == 1.0){
        float thickness_value = 1.0 - contour.y/ float(CONTOUR_DETECTION_KERNEL_SIZE);
        float color = pow(contour.z, CONTOUR_COLOR_FALLOFF);
        float thickness = thickness_value >= 1.0 - contour.z ? 1.0 : 0.0;
        out_color = color * thickness;
    }

    /* RENDERTARGETS:4 */
    gl_FragData[0] = vec4(out_color, out_color, out_color, contour.z);
}


//contour texture