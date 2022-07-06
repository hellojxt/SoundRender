#pragma once

#include "macro.h"
#include "modal.h"

namespace SoundRender
{
    class AudioWapper
    {
    public:
        ModalSound *modalSound;
        void init()
        {
            printf("Write AudioWapper init here\n");
        }

        void link_modal(ModalSound *modal)
        {
            modalSound = modal;
        }

        void update()
        {
            ImGui::Text("Here is AudioWapper Module");
            if (modalSound->soundNeedUpdate){
                modalSound->soundNeedUpdate = false;
                printf("Synthesize sound here\n");
            }
        }
    };

}