#version 450
in vec4 gl_FragCoord ; 

layout(location = 0) in vec3 fragColor;
layout(location = 1) in vec2 texCoord;

layout(location = 0) out vec4 outColor;

void main() {
    outColor = vec4(texCoord, 0.0, 1.0);
}