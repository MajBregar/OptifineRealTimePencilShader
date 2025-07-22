#version 120

varying vec2 TexCoords;


uniform sampler2D colortex2;   //lightmap
uniform sampler2D colortex3;   // block face UVs
uniform sampler2D colortex4;    //final countour map

uniform sampler2D colortex6;    //pencil shading texture
uniform sampler2D depthtex1; 

uniform float viewWidth;
uniform float viewHeight;

const float light_levels = 64.0;

const float ub = 0.6;
const float uw = 0.7;
const float threshold = 0.95;

bool isSky(vec2 uv) {
    float depth = texture2D(depthtex1, uv).r;
    return depth == 1.0;
}

vec2 rotateUV90(vec2 uv) {
    uv -= 0.5;
    uv = vec2(-uv.y, uv.x);
    uv += 0.5;
    return uv;
}

float remap_light_level(float light_level) {
    float lin_light = pow(light_level, 2.2);
    float l = pow(lin_light, 1.0 / 2.5) + 0.05;
    return clamp(l, 0.0, 1.0);
}

float quantize_light_level(float light_level){
    return floor(light_level * (light_levels - 1.0) + 0.5) / (light_levels - 1.0);
}

float level_to_offset(float light_level){
    return (floor((1.0 - light_level) * (light_levels - 1.0))) / light_levels;
}


float blend_function(float ct, float cs) {
    float ca = ct * (1.0 - cs);
    return ct - ub * ca;
}

void main() {
    float contour = texture2D(colortex4, TexCoords).r;
    
    float light_block = texture2D(colortex2, TexCoords).r;
    float light_sky = texture2D(colortex2, TexCoords).g;
    float light_level = max(light_sky, light_block);
    float raw_light_level = remap_light_level(light_level);
    light_level = quantize_light_level(raw_light_level);

    vec3 texture_output = vec3(1.0);
    if (!isSky(TexCoords)) {
        

        float light_offset = level_to_offset(light_level);

        vec2 raw_uv = texture2D(colortex3, TexCoords).rg;
        vec2 local_uv = raw_uv * vec2(1.0 / light_levels, 1.0);
        vec2 local_uv_rot = rotateUV90(raw_uv) * vec2(1.0 / light_levels, 1.0);

        vec2 ct_sample_uv = vec2(local_uv.x + light_offset, local_uv.y);
        float ct = texture2D(colortex6, ct_sample_uv).r;

        vec2 cs_sample_uv = vec2(local_uv_rot.x + light_offset, local_uv_rot.y);
        float cs = texture2D(colortex6, cs_sample_uv).r;

        float angle = radians(-45.0);
        mat2 rotation_matrix = mat2(cos(angle), -sin(angle), sin(angle),  cos(angle));
        vec2 cs2_sample_uv = rotation_matrix * raw_uv ;
        cs2_sample_uv.x = abs(cs2_sample_uv.x);
        cs2_sample_uv = cs2_sample_uv * vec2(1.0 / light_levels, 1.0) + vec2(light_offset, 0.0);

        float cs2 = texture2D(colortex6, cs2_sample_uv).r;

        //float ct1 = blend_function(ct, cs).r;
        //texture_output = blend_function(ct1, cs2);
        float final_color = blend_function(blend_function(ct, cs), cs2);

        texture_output = vec3(final_color);
    }

    texture_output = contour < 1.0 ? vec3(contour) : texture_output;

    /* RENDERTARGETS:0 */
    gl_FragData[0] = vec4(texture_output, 1.0);
}

