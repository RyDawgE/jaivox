#version 450
in vec4 gl_FragCoord ; 

layout(location = 0) in vec3 fragPos;
layout(location = 1) in vec3 fragNormal;
layout(location = 2) in vec2 texCoord;

layout(location = 0) out vec4 outColor;

uniform vec3 lightPos;  

uniform sampler2D Sampler;

void main() {
    vec3 norm = normalize(fragNormal);
    vec3 lightDir = normalize(lightPos - fragPos);  
    vec3 lightColor = vec3(.5, .5, .5);
    float ambientIntensity = .75;
    float lightIntensity = .75;
    
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * (lightColor * lightIntensity);
    
    outColor = (vec4(diffuse, 1.0) + vec4(ambientIntensity)) * texture(Sampler, texCoord);
    
    //outColor = vec4(normalize(fragNormal), 0);
    //outColor = texture(Sampler, texCoord);
    //outColor = vec4(texCoord, 0, 1);
}