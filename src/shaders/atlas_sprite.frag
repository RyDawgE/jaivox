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

//These should prolly not be uniforms, but rather get uploaded
//To some buffer
uniform int atlas_get_x=1;
uniform int atlas_get_y=1;
uniform int atlas_size_x=1;
uniform int atlas_size_y=1;

void main()
{
    vec2 pos = vec2(
        (TexCoords.x + atlas_get_x) / atlas_size_x,
        (TexCoords.y + atlas_get_y) / atlas_size_y
    );
    color = texture(image, pos);
}