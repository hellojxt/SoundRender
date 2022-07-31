#pragma once
#include "window.h"
#include "audio.h"
#include "modal.h"
#include <filesystem>
#include "string.h"

namespace SoundRender
{
    class AudioWindow : public Window
    {
    public:
        AudioWapper audio;
        ModalSound modal;
        std::string filename;
        AudioWindow(std::string filename_){
            filename = filename_;            
        }
        void init()
        {
            title = "audio window";
            audio.init();
            auto pos1 = filename.rfind('/') + 1, pos2 = filename.rfind('.');
            auto basename = filename.substr(pos1, pos2 - pos1);
            auto eigenPath = std::string(ASSET_DIR) + std::string("/eigen/") + basename + std::string(".npz");
            auto ffatPath = std::string(ASSET_DIR) + std::string("/acousticMap/") + basename + std::string(".npz");
            auto voxelPath = std::string(ASSET_DIR) + std::string("/voxel/") + basename + std::string(".npy");
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