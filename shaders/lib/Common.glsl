
/*
const int colortex1Format = RGB16F;
const int colortex2Format = RGB16F;
const int colortex8Format = RGB16F;
const int depthtex0Format = 
*/


const int shadowMapResolution = 2048;
const int noiseTextureResolution = 128;
const float sunPathRotation = 45.0;

const vec3 world_x_normal = vec3(1.0, 0.0, 0.0);
const vec3 world_y_normal = vec3(0.0, 1.0, 0.0);
const vec3 world_z_normal = vec3(0.0, 0.0, 1.0);

const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;

const vec3 forward_facing_vector = vec3(0.0, 0.0, 1.0);
vec2 texelSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);
const float pi = 3.1415927;


float pencil_blend_function(float ct, float cs, float local_UB, float local_UW, float local_THR) {
    float ca = ct * (1.0 - cs);
    ca = ct >= local_THR ? ca * local_UW : ca;
    return ct - local_UB * ca;
}


