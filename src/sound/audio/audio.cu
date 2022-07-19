#include "audio.h"


namespace SoundRender
{
    float AudioWapper::CallbackForSound(AudioWapper* audio)
    {
        return audio->_CallbackForSound();
    }

    float AudioWapper::_CallbackForSound()
    {
        auto& modalInfos = modalSound->modalInfos;

        float soundResult = 0.0f;
        for (auto &modalInfo : modalInfos)
        {
            float dotResult = 0.f;
            for (auto &restForce : restForces)
            {
                size_t id = restForce.first;
                dotResult += (modalInfo.eigenVec[id] + modalInfo.eigenVec[id + 1] +
                              modalInfo.eigenVec[id + 2]) *
                             restForce.second;
            }
            modalInfo.f = dotResult;
            const auto [p, q] = modalSound->GetModalResult(modalInfo);
            soundResult += p * q;
        }

        std::vector<size_t> willDelete;
        for (auto &restForce : restForces)
        {
            restForce.second = GetDeclinedForce(restForce.second);
            if (restForce.second < 1e-5f) // force become 0
            {
                willDelete.push_back(restForce.first);
            }
        }

        if (!willDelete.empty())
        { // clear out 0 force.
            std::lock_guard<std::mutex> _(restForceMutex);
            for (size_t item : willDelete)
            {
                restForces.erase(item);
            }
        }
        return soundResult;
    }

    inline float Lerp(float x1, float x2, float coeff)
    {
        return x1 * coeff + x2 * (1 - coeff);
    }

     std::pair<float, float> AudioWapper::GetModalResult(ModalInfo &modalInfo)
    {
        const float camx = modalSound->mesh_render->camera.Position[0], 
            camy = modalSound->mesh_render->camera.Position[1],
            camz = modalSound->mesh_render->camera.Position[2];
        const size_t ffatColNum = modalInfo.ffat[0].size();
        // Here we need row and col sample intervals are the same, otherwise changes are needed.
        const float sampleIntervalRep = ffatColNum / PI;

        float theta = std::acos(camz);
        float phi = camy <= 1e-5f && camx <= 1e-5f && camx >= 1e-5f && camy >= 1e-5f ? 0.0f : std::atan2(camy, camx) + PI;

        float colInter = theta * sampleIntervalRep, rowInter = phi * sampleIntervalRep;
        size_t col = static_cast<size_t>(colInter);
        float colFrac = colInter - static_cast<float>(col);
        size_t row = static_cast<size_t>(rowInter);
        float rowFrac = rowInter - static_cast<float>(row);
        // bi-Lerp.
        float interResult = Lerp(Lerp(modalInfo.ffat[row][col], modalInfo.ffat[row + 1][col], rowFrac),
                                 Lerp(modalInfo.ffat[row][col + 1], modalInfo.ffat[row + 1][col + 1], rowFrac), colFrac);

        float p = interResult / (camx * camx + camy * camy + camz * camz);
        float q = modalInfo.coeff1 * modalInfo.q1 + modalInfo.coeff2 * modalInfo.q2 + modalInfo.coeff3 * modalInfo.f;
        modalInfo.q2 = modalInfo.q1, modalInfo.q1 = q; // update q.

        //return {p, q};
        return std::pair(p,q);
    };
}