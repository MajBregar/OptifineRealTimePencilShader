#version 120

varying vec2 TexCoords;
varying vec3 Normal;
varying vec2 TangentScreenDir1;
varying vec2 TangentScreenDir2;

uniform sampler2D gtexture;

void main(){
    vec4 a = texture2D(texture, TexCoords);

    vec2 encoded_tan1 = 0.5 * TangentScreenDir1 + 0.5;
    vec2 encoded_tan2 = 0.5 * TangentScreenDir2 + 0.5;

    /* DRAWBUFFERS:0167 */
    gl_FragData[0] = a;
    gl_FragData[1] = vec4(Normal, 1.0);
    gl_FragData[2] = vec4(encoded_tan1, 0.0, 1.0);
    gl_FragData[3] = vec4(encoded_tan2, 0.0, 1.0);
}