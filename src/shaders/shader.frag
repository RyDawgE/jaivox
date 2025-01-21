#version 450
in vec4 gl_FragCoord ; 

layout(location = 0) in vec3 fragColor;
layout(location = 1) in vec2 texCoord;

layout(location = 0) out vec4 outColor;

uniform sampler2D Sampler;

void main() {
    outColor = texture(Sampler, texCoord);
}