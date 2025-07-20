#version 120

varying vec2 TexCoords;
uniform sampler2D colortex0;

void main() {
    vec3 c = texture2D(colortex0, TexCoords).rgb;
    gl_FragColor = vec4(c, 1.0f);
}