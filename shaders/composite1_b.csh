#version 430
#define COMPOSITE
#define COMPUTE_SHADER
#include "lib/Inc.glsl"

layout(local_size_x = 16, local_size_y = 16) in;

layout(rgba16f) uniform image2D colorimg4;
layout(r32ui) uniform uimage2D colorimg5;

ivec2 get_resolution() {
    return ivec2(int(viewWidth), int(viewHeight));
}

float decodeDepth(uint d) {
    return float(d) / DEPTH_SCALE_F;
}

void main() {
    ivec2 pixelCoord = ivec2(gl_GlobalInvocationID.xy);
    ivec2 resolution = get_resolution();

    if (pixelCoord.x >= resolution.x || pixelCoord.y >= resolution.y) return;

    uint enc_depth = imageLoad(colorimg5, pixelCoord).r;
    float depth = decodeDepth(enc_depth);

    if (depth > 1.0){
        float background_depth = decodeDepth(enc_depth - DEPTH_SCALE_U);
        if (background_depth > 1.0) return;

        imageStore(colorimg4, pixelCoord, vec4(vec3(0.0), background_depth));
        return;
    };

    float color = CONTOUR_COLOR_FALLOFF == 0.0 ? 1.0 : clamp(1.0 - pow(depth, CONTOUR_COLOR_FALLOFF), CONTOUR_COLOR_FALLOFF_MINIMUM, 1.0);

    imageStore(colorimg4, pixelCoord, vec4(vec3(color), depth));
}
