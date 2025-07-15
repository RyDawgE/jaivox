#version 430 core

in vec2 TexCoords;
out vec4 color;

layout (std140, binding = 0) uniform GameState
{
    mat4    projection;
    uint    frame;
    float   time;
    float   dt;
};

uniform sampler2D image;
uniform int num_frames=4;
uniform int curr_frame=0;

void main()
{
    float pos = mod(curr_frame, num_frames);
    color = texture(image, vec2((TexCoords.x + pos) / num_frames, TexCoords.y));
}