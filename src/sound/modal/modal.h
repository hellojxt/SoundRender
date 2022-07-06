#pragma once

#include "macro.h"
#include "window.h"
namespace SoundRender
{
    class ModalSound
    {
    public:
        float force;
        bool soundNeedUpdate = false;
        MeshRender *mesh_render;
        void init()
        {
            printf("Write ModalSound init here\n");
        }

        void link_mesh_render(MeshRender *mesh_render)
        {
            this->mesh_render = mesh_render;
        }

        void update()
        {
            ImGui::Text("Here is ModalSound Module");
            ImGui::Text("Mesh has %d vertices and %d triangles", mesh_render->vertices.size(), mesh_render->triangles.size());
            ImGui::Text("Camera position:  (%f, %f, %f)", mesh_render->camera.Position.x, mesh_render->camera.Position.y, mesh_render->camera.Position.z);
            ImGui::SliderFloat("Click Force", &force, 0.0f, 1.0f);
            ImGui::Text("Force: %f", force);
            ImGui::Text("Selected Triangle Index: %d", mesh_render->selectedTriangle);
            if (ImGui::IsKeyDown(ImGui::GetKeyIndex(ImGuiKey_Space)))
            {
                printf("Space key is down and click sound is synthesized\n");
                soundNeedUpdate = true;
            }
        }
    };
}