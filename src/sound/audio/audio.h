#pragma once

#include "macro.h"
#include "modal.h"
#include "helper_math.h"

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
            if (modalSound->soundNeedUpdate)
            {
                modalSound->soundNeedUpdate = false;
                int triID = modalSound->mesh_render->selectedTriangle;
                if(triID < 0)
                    return;
                auto selectedVertIDs = modalSound->mesh_render->triangles[triID];
                auto& vertArr = modalSound->mesh_render->vertices;

                auto center = vertArr[selectedVertIDs.x] + vertArr[selectedVertIDs.y] + vertArr[selectedVertIDs.z];

                const auto[i, j, k] = modalSound->GetNormalizedID(center.x, center.y, center.z);
                auto e1 = vertArr[selectedVertIDs.x] - vertArr[selectedVertIDs.y], e2 = vertArr[selectedVertIDs.y] - vertArr[selectedVertIDs.z];
                auto norm = cross(e1, e2); 

                for (auto &offset : MaterialConst::offsets)
                {
                    size_t id = modalSound->vertData[i + offset[0]][j + offset[1]][k + offset[2]] * 3; 
                    for(auto& modalInfo : modalSound->modalInfos)
                    {
                        modalInfo.f += modalInfo.eigenVec[id] * norm.x + modalInfo.eigenVec[id + 1] * norm.y
                            + modalInfo.eigenVec[id + 2] * norm.z;
                    }
                }

                float force = modalSound->force;
                for(auto& modalInfo : modalSound->modalInfos)
                {
                    modalInfo.f *= force / 8; // eight verts average.
                }

                printf("Synthesize sound here\n");
            }
        }

        static float CallbackForSound(AudioWapper* audio);

    private:
        std::pair<float, float> GetModalResult(ModalInfo &modalInfo);
        float _CallbackForSound();
    };

}