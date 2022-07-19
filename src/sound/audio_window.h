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

            auto assetDir = std::filesystem::current_path().parent_path() / "asset";

            auto eigenPath = (assetDir / "eigen") / "bunny.npz";
            auto ffatPath = (assetDir / "acousticMap") / "bunny.npz";
            auto voxelPath = (assetDir / "voxel") / "bunny.npy";
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
        
    };
}