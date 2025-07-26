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

vec3 hueShift( vec3 color, float hueAdjust ){

    const vec3  kRGBToYPrime = vec3 (0.299, 0.587, 0.114);
    const vec3  kRGBToI      = vec3 (0.596, -0.275, -0.321);
    const vec3  kRGBToQ      = vec3 (0.212, -0.523, 0.311);

    const vec3  kYIQToR     = vec3 (1.0, 0.956, 0.621);
    const vec3  kYIQToG     = vec3 (1.0, -0.272, -0.647);
    const vec3  kYIQToB     = vec3 (1.0, -1.107, 1.704);

    float   YPrime  = dot (color, kRGBToYPrime);
    float   I       = dot (color, kRGBToI);
    float   Q       = dot (color, kRGBToQ);
    float   hue     = atan (Q, I);
    float   chroma  = sqrt (I * I + Q * Q);

    hue += hueAdjust;

    Q = chroma * sin (hue);
    I = chroma * cos (hue);

    vec3    yIQ   = vec3 (YPrime, I, Q);

    return vec3( dot (yIQ, kYIQToR), dot (yIQ, kYIQToG), dot (yIQ, kYIQToB) );

}

void main()
{
    float pos = mod(curr_frame, num_frames);
    color = texture(image, vec2(((TexCoords.x + pos) / num_frames ), TexCoords.y));
    color = vec4(
        hueShift(
            vec3(color.x, color.y, color.z),
            time*3 + ((TexCoords.y + TexCoords.x)*3) ),
         color.z);
}