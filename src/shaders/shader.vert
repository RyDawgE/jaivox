#version 450

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inColor;

layout(location = 0) out vec3 fragColor;

void main() {
    //gl_Position = vec4(inPosition, 1.0);
    gl_Position = proj * view * model * vec4(inPosition, 1.0);
    //Uncomment to make vulkan work again ^^

    fragColor = inColor;
}