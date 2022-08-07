#version 430 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in int flag;
layout (location = 3) in vec3 aTex;

out vec3 FragPos;
out vec3 Normal;
flat out int Flag;
out vec3 TexCoord;
out vec3 refraction;
out vec3 reflection;
out float fresnel;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 viewPos; 

// uniform vec3 objectColor;

const float Air = 1.0;
const float Glass = 1.5714;
const float R0 = ((Air - Glass) * (Air - Glass)) / ((Air + Glass) * (Air + Glass));
const float RelaN = Air / Glass;

void main()
{   
    FragPos = vec3(view * model * vec4(aPos, 1.0));
    Normal = mat3(transpose(inverse(model))) * aNormal;  
    Normal = vec3(view * vec4(Normal, 0.0));
    gl_Position = projection * vec4(FragPos, 1.0);
    Flag = flag;
    TexCoord = aTex;
    vec3 viewDir = normalize(aPos - viewPos);
    vec3 norm = normalize(Normal);
    refraction = refract(viewPos, norm, RelaN);
    reflection = reflect(viewPos, norm);
    fresnel = R0 + (1.0 - R0) * pow((1.0 - dot(-viewDir, norm)), 5.0);
    return;
}