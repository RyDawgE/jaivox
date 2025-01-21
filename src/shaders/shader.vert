#version 450

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inTexCoord;

layout(location = 0) out vec3 fragPos;
layout(location = 1) out vec3 fragNormal;
layout(location = 2) out vec2 texCoord;

void main() {
    gl_Position = proj * view * model * vec4(inPosition, 1.0);
    fragPos     = vec3(model * vec4(inPosition, 1.0));
    fragNormal  = inNormal;
    texCoord    = inTexCoord;
}