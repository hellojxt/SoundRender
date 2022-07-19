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
            if (modalSound->soundNeedUpdate)
            {
                modalSound->soundNeedUpdate = false;
                int triID = modalSound->mesh_render->selectedTriangle;
                if(triID < 0)
                    return;
                size_t voxelNum = modalSound->vertData.size() - 1;
                auto CoordToID = [=](float c)
                { return static_cast<size_t>((c + 0.5f) * voxelNum - 0.5f); };
                
                auto selectedVertIDs = modalSound->mesh_render->triangles[triID];
                const auto& vertArr = modalSound->mesh_render->vertices;
                float centerx = (vertArr[selectedVertIDs.x].x + vertArr[selectedVertIDs.y].x + vertArr[selectedVertIDs.z].x) / 3,
                    centery = (vertArr[selectedVertIDs.x].y + vertArr[selectedVertIDs.y].y + vertArr[selectedVertIDs.z].y) / 3,
                    centerz = (vertArr[selectedVertIDs.x].z + vertArr[selectedVertIDs.y].z + vertArr[selectedVertIDs.z].z) / 3;

                size_t i = CoordToID(centerx), j = CoordToID(centery), k = CoordToID(centerz);

                std::lock_guard<std::mutex> _(restForceMutex);

                float force = modalSound->force;
                for (auto &offset : MaterialConst::offsets)
                {
                    size_t id = modalSound->vertData[i + offset[0]][j + offset[1]][k + offset[2]];
                    auto pos = restForces.find(id * 3); // to adjust 3-D coordinate.
                    if (pos == restForces.end())
                        restForces.emplace(id, force);
                    else
                        pos->second += force;
                }

                printf("Synthesize sound here\n");
            }
        }

        static float CallbackForSound(AudioWapper* audio);

    private:
        std::unordered_map<size_t, float> restForces;
        std::mutex restForceMutex;
        std::pair<float, float> GetModalResult(ModalInfo &modalInfo);
        static float GetDeclinedForce(float inputForce) {return 0.99f * inputForce;};
        float _CallbackForSound();
    };

}