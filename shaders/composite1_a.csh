#version 430
#define COMPOSITE
#define COMPUTE_SHADER
#include "lib/Inc.glsl"

layout(local_size_x = 16, local_size_y = 16) in;

layout(rg16) uniform image2D colorimg3;
layout(r32ui) uniform uimage2D colorimg4;

ivec2 get_resolution() {
    return ivec2(int(viewWidth), int(viewHeight));
}

uint encode_depth(float d) {
    return uint(d * DEPTH_SCALE_F + 0.5);
}

void main() {
    ivec2 pixelCoord = ivec2(gl_GlobalInvocationID.xy);
    ivec2 resolution = get_resolution();

    if (pixelCoord.x >= resolution.x || pixelCoord.y >= resolution.y) return;

    vec4 center = imageLoad(colorimg3, pixelCoord);
    float depth = center.g;

    if (center.r < 1.0){
        imageAtomicMin(colorimg4, pixelCoord, encode_depth(depth) + DEPTH_SCALE_U);
        return;
    }

    float thickness_adjustment = CONTOUR_THICKNESS_FALLOFF == 0.0 ? 0.0 : pow(depth, CONTOUR_THICKNESS_FALLOFF);
    int expansion_kernel_size = int(round(float(CONTOUR_DETECTION_KERNEL_SIZE) * (1.0 - thickness_adjustment)));

    for (int dx = -expansion_kernel_size; dx <= expansion_kernel_size; dx++) {
        for (int dy = -expansion_kernel_size; dy <= expansion_kernel_size; dy++) {
            if (dx * dx + dy * dy > expansion_kernel_size * expansion_kernel_size) continue;

            ivec2 target = pixelCoord + ivec2(dx, dy);
            if (target.x < 0 || target.y < 0 || target.x >= resolution.x || target.y >= resolution.y) continue;

            imageAtomicMin(colorimg4, target, encode_depth(depth));
        }
    }
}
