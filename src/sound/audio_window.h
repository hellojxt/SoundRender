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
            auto modalName = filename.substr(pos1, pos2 - pos1);
            modal.init(modalName);
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