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
            // Not compile?
            // auto assetDir = std::string(ASSET_DIR);
            // auto eigenPath = assetDir + "eigen/bunny.npz";
            // auto ffatPath = assetDir + "acousticMap/bunny.npz";
            // auto voxelPath = assetDir + "voxel/bunny.npy";

#if defined(_WIN32)
            //for windows
            //the linux-way path-fetching as below is not suitable on Windows because of the difference between wchar_t & char 
            auto eigenPath = std::string(ASSET_DIR) + std::string("/eigen/bunny.npz");
            auto ffatPath = std::string(ASSET_DIR) + std::string("/acousticMap/bunny.npz");
            auto voxelPath = std::string(ASSET_DIR) + std::string("/voxel/bunny.npy");
            

#else
            //for linux
            auto assetDir = std::filesystem::current_path().parent_path() / "asset";
            auto eigenPath = (assetDir / "eigen") / "bunny.npz";
            auto ffatPath = (assetDir / "acousticMap") / "bunny.npz";
            auto voxelPath = (assetDir / "voxel") / "bunny.npy";
#endif
           


           

            modal.init((const char* )eigenPath.c_str(), (const char*)ffatPath.c_str(), (const char*)voxelPath.c_str());
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
        
    };
}