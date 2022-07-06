#pragma once
#include "window.h"
#include "audio.h"
#include "modal.h"

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
            modal.init();
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