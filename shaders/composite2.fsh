#version 120

varying vec2 TexCoords;

uniform sampler2D colortex9; //final contour_map


void main() {
    vec3 contour = texture2D(colortex9, TexCoords).rgb;
    
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(contour, 1.0);
}
