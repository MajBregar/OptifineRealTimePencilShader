#version 120

varying vec2 TexCoords;

uniform sampler2D colortex8;    //pencil shading texture

uniform sampler2D colortex9;    //final countour map
uniform sampler2D colortex10;   //lightmap
uniform sampler2D colortex11; // block face UVs
uniform sampler2D depthtex0; 

const float light_levels = 32.0;

const float ub = 0.7;
const float uw = 0.5;
const float threshold = 0.95;

bool isSky(vec2 uv) {
    float depth = texture2D(depthtex0, uv).r;
    return depth >= 0.999;
}

vec2 rotateUV90(vec2 uv) {
    uv -= 0.5;                  // Translate to center
    uv = vec2(-uv.y, uv.x);     // Rotate 90° CCW
    uv += 0.5;                  // Translate back
    return uv;
}


float remap_light_level(float light_level){
    //light_level = pow(light_level, 3) + 0.1;
    return clamp(light_level * 1.1, 0.0, 1.0);
}

float level_to_offset(float light_level){
    return (floor((1.0 - light_level) * (light_levels - 1.0))) / light_levels;
}


vec3 blend_function(float ct, float cs) {
    float ca = ct * (1.0 - cs);
    return vec3(ct - ub * ca);
}

void main() {
    float contour = texture2D(colortex9, TexCoords).r;

    //int light_level = int(clamp(light_sky, 0.0, 1.0) * (light_levels - 1) + 0.5);

    vec3 texture_output = vec3(1.0);

    if (!isSky(TexCoords)) {
        //no sky - block have valid light maps
        float light_block = texture2D(colortex10, TexCoords).r;

        float light_sky = remap_light_level(texture2D(colortex10, TexCoords).g);
        float light_offset = level_to_offset(light_sky);

        vec2 local_uv = texture2D(colortex11, TexCoords).rg;
        vec2 local_uv_rot = rotateUV90(local_uv);
        local_uv.x = local_uv.x / light_levels;
        local_uv_rot.x = local_uv_rot.x / light_levels;

        vec2 ct_sample_uv = vec2(local_uv.x + light_offset, local_uv.y);
        float ct = texture2D(colortex8, ct_sample_uv).r;

        vec2 cs_sample_uv = vec2(local_uv_rot.x + light_offset, local_uv_rot.y);
        float cs = texture2D(colortex8, cs_sample_uv).r;

        texture_output = blend_function(ct, cs);
    }

    texture_output = contour < 1.0 ? vec3(contour) : texture_output;

    /* RENDERTARGETS:0 */
    gl_FragData[0] = vec4(texture_output, 1.0);
}

