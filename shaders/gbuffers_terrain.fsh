#version 120
#include "lib/Uniforms.inc"
#include "lib/Common.inc"


varying vec2 TexCoords;
varying vec2 Lightmap;
varying vec3 ViewNormal;
varying vec3 WorldPos;
varying vec3 WorldNormal;
varying vec3 ModelPos;

varying vec4 Color;



void main(){
    vec4 c = texture2D(texture, TexCoords) * Color;

    //model pos is actually world pos

    /* RENDERTARGETS:0,1,2,3,10,11,8 */
    gl_FragData[0] = c;
    gl_FragData[1] = vec4(WorldNormal, 1.0);
    gl_FragData[2] = vec4(Lightmap, 0.0, 1.0);
    gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
    gl_FragData[4] = vec4(ModelPos, 1.0);
    gl_FragData[5] = vec4(ViewNormal, 1.0);
    gl_FragData[6] = vec4(WorldPos, 1.0);

}