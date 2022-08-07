#pragma once
#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include "imgui.h"
#include "implot.h"
#include "implot_internal.h"
#include "backends/imgui_impl_glfw.h"
#include "backends/imgui_impl_opengl3.h"
#include <string>
#include <set>
#include "macro.h"
#include "implot.h"
#include "shader.h"
#include "camera.h"
#include "array.h"
#include "objIO.h"

namespace SoundRender
{
    // float3 texture is used for padding.
    // Strictly, use alignof(...) to regulate is a more proper way.
    class Triangle
    {
    public:
        float3 v1;
        float3 n1;
        float3 t1;
        int flag1;
        float3 v2;
        float3 n2;
        float3 t2;
        int flag2;
        float3 v3;
        float3 n3;
        float3 t3;
        int flag3;
    };

    class Window
    {
    public:
        std::string title;
        virtual void update() = 0;
        virtual void init() = 0;
        void called()
        {
            ImGui::Begin(title.c_str());
            update();
            ImGui::End();
        }
    };

    class MeshRender : public Window
    {
    public:
        unsigned int framebuffer;
        unsigned int textureColorbuffer;
        unsigned int rbo;
        unsigned int meshVAO, meshVBO;
        unsigned int textureID, skycubeID;
        CArr<float3> vertices; 
        CArr<int3> triangles;
        GArr<float3> vertices_g;
        GArr<int3> triangles_g;
        GArr<int3> textriangles_g;
        GArr<float3> texverts_g;
        CArr<Triangle> meshData;
        GArr<Triangle> meshData_g;
        float3 bbox_min;
        float3 bbox_max;
        int selectedTriangle = -1;
        bool soundNeedsUpdate = false;
        bool meshNeedsUpdate = false;
        ImVec2 wsize;
        std::vector<glm::vec3> pointLightPositions;
        Camera camera;
        glm::mat4 camera_projection;
        glm::mat4 camera_view;
        bool inDrag = false;
        float dragX = 0, dragY = 0;
        Material material;
        std::string mtlLib;

#define OVERSAMPLE 2

        Shader shader;
        MeshRender()
        {
            title = "mesh render";
            camera = Camera(glm::vec3(0.0f, 0.0f, 4.0f));
            wsize = ImVec2(0, 0);
            pointLightPositions.push_back(glm::vec3(-2.0f, 4.0f, 5.0f));
            pointLightPositions.push_back(glm::vec3(-2.3f, 4.0f, 5.0f));
            pointLightPositions.push_back(glm::vec3(-2.3f, 4.0f, 5.0f));
        };

        void init();

        void resize();

        // mouse middle button for camera rotation and zoom
        void event();

        void load_mesh(CArr<float3> vertices_, CArr<int3> triangles_, CArr<float3> texverts_, CArr<int3> textris_);
        void loadTexture(const char* path);
        void loadSkycube(const std::string& path);
        void Prepare(std::string mtlLibName);

        void updateMesh();
        void resetMesh();
        void changeMaterial(int chosenID);

        void update();

    };

}