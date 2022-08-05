#version 430 core
out vec4 FragColor;
#define NR_POINT_LIGHTS 3
in vec3 Normal;  
in vec3 FragPos;  
in vec3 TexCoord;
flat in int Flag;

uniform vec3 lightPos[NR_POINT_LIGHTS];
uniform vec3 viewPos; 
uniform vec3 lightColor;
uniform sampler2D Texture;
uniform vec3 selectedColor;

uniform vec3 ambientCoeff;
uniform vec3 diffuseCoeff;
uniform vec3 specularCoeff;
uniform float specularExp;
uniform float alpha;
uniform int useTexture;

void main()
{
    vec3 objColor;
    if(Flag == 1)
      objColor = selectedColor;
    else if(useTexture == 1)
      objColor = texture2D(Texture, vec2(TexCoord.s, 1.0 - TexCoord.t)).rgb;
    else
      objColor = vec3(1.0, 1.0, 1.0);
    // ambient
    // float ambientStrength = 0.2;
    vec3 ambient = ambientCoeff * lightColor;
  	vec3 result = ambient;
    for (int i = 0; i < NR_POINT_LIGHTS; i++)
    {
        // diffuse 
        vec3 norm = normalize(Normal);
        vec3 lightDir = normalize(lightPos[i] - FragPos);
        float diff = max(dot(norm, lightDir), 0.0);
        vec3 diffuse = diffuseCoeff * diff * lightColor;

        // specular
        // float specularStrength = 0.2;
        vec3 viewDir = normalize(vec3(0,0,0) - FragPos);
        vec3 reflectDir = reflect(-lightDir, norm);  
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), specularExp);
        vec3 specular = specularCoeff * spec * lightColor;  
        result += (diffuse + specular)*objColor / NR_POINT_LIGHTS;
    }
    FragColor = vec4(result, alpha);
} 