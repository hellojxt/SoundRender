#ifndef CAMERA_H
#define CAMERA_H

#include <GL/glew.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include <vector>



// Default camera values
const float YAW         = -90.0f;
const float PITCH       =  0.0f;
const float SPEED       =  2.5f;
const float ROTATE_SPEED  =  0.02f;
const float SENSITIVITY =  0.1f;
const float ZOOM        =  55.0f;


// An abstract camera class that processes input and calculates the corresponding Euler Angles, Vectors and Matrices for use in OpenGL
class Camera
{
public:
    // camera Attributes
    glm::vec3 Position;
    glm::vec3 Up;

    // camera options
    float MovementSpeed;
    float MouseSensitivity;
    float Zoom;

    // constructor with vectors
    Camera(glm::vec3 position = glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3 up = glm::vec3(0.0f, 1.0f, 0.0f)) : Zoom(ZOOM)
    {
        Position = position;
        Up = up;
    }

    void rotate(float amount, glm::vec3& axis)
    {
        glm::mat4 rotation = glm::rotate(glm::mat4(1.0f), -amount * ROTATE_SPEED, axis);
        Position = glm::vec3(rotation * glm::vec4(Position, 1.0f));
        Up = glm::vec3(rotation * glm::vec4(Up, 1.0f));
    }

    glm::vec3 Front(){
        return -Position;
    }

    glm::vec3 Right(){
        return glm::normalize(glm::cross(Front(), Up));
    }

    // returns the view matrix calculated using Euler Angles and the LookAt Matrix
    glm::mat4 GetViewMatrix()
    {
        return glm::lookAt(Position, glm::vec3(0.0f, 0.0f, 0.0f), Up);
    }

    // processes input received from a mouse scroll-wheel event. Only requires input on the vertical wheel-axis
    void ProcessMouseScroll(float yoffset)
    {
        Zoom -= (float)yoffset*Zoom*0.05f;
        if (Zoom < 15.0f)
            Zoom = 15.0f;
        if (Zoom > 75.0f)
            Zoom = 75.0f; 
    }

    
};
#endif