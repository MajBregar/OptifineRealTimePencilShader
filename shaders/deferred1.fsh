#version 330
#include "lib/Uniforms.glsl"
#include "lib/Geometry.glsl"
#include "lib/Common.glsl"
#include "lib/Shadows.glsl"

varying vec2 TexCoords;

#define KERNEL_THR 0
#define KERNEL_DIM CONTOUR_DETECTION_KERNEL_SIZE * 2 + 1
#define CONTOUR_THICKNESS_STEP 1.0 / CONTOUR_DETECTION_KERNEL_SIZE

vec3 inflate_and_filter_contour(vec2 uv){
    vec4 center_contour = texture2D(colortex4, uv);
    if (center_contour.r == 1.0) return vec3(1.0, 0.0, center_contour.a);

    int detected_count = 0;
    float min_dist = float(KERNEL_DIM);
    float depth = 1.0;

    for (int x = -CONTOUR_DETECTION_KERNEL_SIZE; x <= CONTOUR_DETECTION_KERNEL_SIZE; x++){
        for (int y = -CONTOUR_DETECTION_KERNEL_SIZE; y <= CONTOUR_DETECTION_KERNEL_SIZE; y++){
            if (x == 0 && y == 0) continue;

            vec2 sample_uv = uv + vec2(x * texelSize.x, y * texelSize.y);
            vec4 neighbour_contour = texture2D(colortex4, sample_uv);

            if (neighbour_contour.r < 0.99) continue;

            detected_count++;
            float dist = abs(float(x)) + abs(float(y));

            if (dist < min_dist){
                min_dist = dist;
                depth = neighbour_contour.a;
            }                
            
        }
    }

    if (detected_count > KERNEL_THR) return vec3(1.0, min_dist, depth);
    return vec3(0.0, 0.0, 1.0);
}

void main() {
    
    vec3 contour = inflate_and_filter_contour(TexCoords);

    vec3 contour_strength = vec3(0.0);

    vec3 test = vec3(0.0);

    if (contour.x == 1.0){

        float thickness_value = 1.0 - contour.y / float(CONTOUR_DETECTION_KERNEL_SIZE);

        float color = CONTOUR_COLOR_FALLOFF == 0.0 ? 1.0 : clamp(1.0 - pow(contour.z, CONTOUR_COLOR_FALLOFF), CONTOUR_COLOR_FALLOFF_MINIMUM, 1.0);

        float thickness_falloff = CONTOUR_THICKNESS_FALLOFF == 0.0 ? 0.0 : pow(contour.z, CONTOUR_THICKNESS_FALLOFF);
        float thickness = thickness_value >= thickness_falloff ? 1.0 : 0.0;
        
        contour_strength = vec3(thickness * color);
    }

    /* RENDERTARGETS:4 */
    gl_FragData[0] = vec4(contour_strength, contour.z);
}
