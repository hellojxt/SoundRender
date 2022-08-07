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
        int select_object_idx = 0;
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
            
            if (ImGui::TreeNode("Object Model"))
            {
                for (int n = 0; n < basename_lst.size(); n++)
                {
                    if (ImGui::Selectable(basename_lst[n].c_str(), select_object_idx == n))
                    {
                        if (select_object_idx != n)
                        {
                            select_object_idx = n;
                            audio.material_select_idx = 0;
                            modal.SetMaterial(0, true);
                            init();
                        }
                    }
                }
                ImGui::TreePop();
            }

            modal.update();

            ImGui::Text("\n");

            audio.update();

        }
        ~AudioWindow() { audio.close(); }
    };
}