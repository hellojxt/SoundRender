#pragma once
#include "window.h"
#include "audio.h"
#include "modal.h"
#include <filesystem>

namespace SoundRender
{
    class AudioWindow : public Window
    {
    public:
        AudioWapper audio;
        ModalSound modal;
        void init()
        {
            title = "audio window";
            audio.init();

            auto eigenPath = std::string(ASSET_DIR) + std::string("/eigen/bunny.npz");
            auto ffatPath = std::string(ASSET_DIR) + std::string("/acousticMap/bunny.npz");
            auto voxelPath = std::string(ASSET_DIR) + std::string("/voxel/bunny.npy");

            modal.init(eigenPath.c_str(), ffatPath.c_str(), voxelPath.c_str());
        }
        
        void link_mesh_render(MeshRender* mesh)
        {
            modal.link_mesh_render(mesh);
            audio.link_modal(&modal);
        }
        
        void update()
        {
            modal.update();
            ImGui::Text("\n");
            audio.update();
        }
        ~AudioWindow() { audio.close();}
    };
}