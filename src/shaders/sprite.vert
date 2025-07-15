#version 430 core
layout (location = 0) in vec4 vertex; // <vec2 position, vec2 texCoords>



layout (std140, binding = 0) uniform GameState
{
    mat4    projection;
    uint    frame;
    float   time;
    float   dt;
};

uniform mat4 model;

out vec2 TexCoords;

void main()
{
    TexCoords = vertex.zw;
    gl_Position = projection * model * vec4(vertex.xy, 0.0, 1.0);
}