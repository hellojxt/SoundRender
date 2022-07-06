#version 430 core
out vec4 FragColor;
#define NR_POINT_LIGHTS 3
in vec3 Normal;  
in vec3 FragPos;  
in vec3 FragObjColor;

uniform vec3 lightPos[NR_POINT_LIGHTS];
uniform vec3 viewPos; 
uniform vec3 lightColor;


void main()
{
    // ambient
    float ambientStrength = 0.2;
    vec3 ambient = ambientStrength * lightColor;
  	vec3 result = ambient;
    for (int i = 0; i < NR_POINT_LIGHTS; i++)
    {
        // diffuse 
        vec3 norm = normalize(Normal);
        vec3 lightDir = normalize(lightPos[i] - FragPos);
        float diff = max(dot(norm, lightDir), 0.0);
        vec3 diffuse = diff * lightColor;

        // specular
        float specularStrength = 0.2;
        vec3 viewDir = normalize(vec3(0,0,0) - FragPos);
        vec3 reflectDir = reflect(-lightDir, norm);  
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
        vec3 specular = specularStrength * spec * lightColor;  
        result += (diffuse + specular)*FragObjColor / NR_POINT_LIGHTS;
    }
    FragColor = vec4(result, 1.0);
} 