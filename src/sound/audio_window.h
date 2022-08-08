#pragma once
#include "window.h"
#include "audio.h"
#include "modal.h"
#include <filesystem>
#include "string.h"
#include <vector>

namespace SoundRender
{
    class AudioWindow : public Window
    {
    public:
        AudioWapper audio;
        ModalSound modal;
        int select_object_idx = 2;
        int material_select_idx = 0;
        std::vector<std::string> filename_lst;
        std::vector<std::string> basename_lst;

        AudioWindow()
        {
            std::string meshPath = std::string(ASSET_DIR) + "/meshes/";
            for (const auto &meshfile : std::filesystem::directory_iterator(meshPath))
            {
                auto mesh = meshfile.path().filename().string();
                filename_lst.push_back(meshPath + mesh);
                // "/home/jxt/SoundRender/asset/meshes/plate.obj" to "plate"
                auto basename = mesh.substr(mesh.find_last_of("/") + 1);
                basename = basename.substr(0, basename.find_last_of("."));
                basename_lst.push_back(basename);
            }
            title = "audio window";
        }
        void init()
        {
            auto filename = filename_lst[select_object_idx];
            LOG("filename: " << filename);
            auto mesh = loadOBJ(filename, true);
            modal.mesh_render->load_mesh(mesh.vertices, mesh.triangles, mesh.vertex_texcoords, mesh.tex_triangles);

            modal.init(filename, 0);
            audio.init();
        }

        void link_mesh_render(MeshRender *mesh)
        {
            modal.link_mesh_render(mesh);
            audio.link_modal(&modal);
            modal.mesh_render->Prepare(MaterialConst::mtlLibName);
        }

        void update()
        {
            ImGui::Text("Objects");
            if (ImGui::BeginListBox("##Object List"))
            {
                for (int n = 0; n < basename_lst.size(); n++)
                {
                    if (ImGui::Selectable(basename_lst[n].c_str(), select_object_idx == n))
                    {
                        if (select_object_idx != n)
                        {
                            select_object_idx = n;
                            material_select_idx = 0;
                            modal.SetMaterial(0, true);
                            init();
                        }
                    }
                }

                ImGui::EndListBox();
            }

            ImGui::Text("Materials");
            if (ImGui::BeginListBox("##Material"))
            {
                for (int n = 0; n < IM_ARRAYSIZE(MaterialConst::names); n++)
                {
                    const bool is_selected = (material_select_idx == n);
                    if (ImGui::Selectable(MaterialConst::names[n].c_str(), is_selected))
                    {
                        if (material_select_idx != n)
                        {
                            material_select_idx = n;
                            modal.init(modal.filename, material_select_idx);
                            modal.SetMaterial(material_select_idx, true);
                        }
                    }
                    // Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                    if (is_selected)
                        ImGui::SetItemDefaultFocus();
                }
                ImGui::EndListBox();
            }

            ImGui::Text("FPS: %.2f", ImGui::GetIO().Framerate);
            modal.update();

            // ImGui::Text("\n");

            audio.update();
        }
        ~AudioWindow() { audio.close(); }
    };
}