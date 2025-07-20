#version 120

varying vec2 TexCoords;
varying vec3 Normal;
varying vec2 TangentScreenDir1;
varying vec2 TangentScreenDir2;

void main() {
    gl_Position = ftransform();

    TexCoords = gl_MultiTexCoord0.st;

    // Transform normal into view space
    vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
    Normal = normal;

    // Create orthogonal basis (tangent and bitangent in world space)
    vec3 up = abs(dot(normal, vec3(0.0, 1.0, 0.0))) > 0.99 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
    vec3 tangent1 = normalize(cross(cross(normal, up), normal));
    vec3 tangent2 = normalize(cross(normal, tangent1));  // orthogonal to tangent1

    // Project both tangents into screen space
    float offset = 0.05;
    vec4 pos = gl_ModelViewProjectionMatrix * gl_Vertex;

    vec4 tip1 = gl_ModelViewProjectionMatrix * (gl_Vertex + vec4(tangent1 * offset, 0.0));
    vec4 tip2 = gl_ModelViewProjectionMatrix * (gl_Vertex + vec4(tangent2 * offset, 0.0));

    vec2 base = pos.xy / pos.w;
    TangentScreenDir1 = normalize((tip1.xy / tip1.w) - base);
    TangentScreenDir2 = normalize((tip2.xy / tip2.w) - base);
}
