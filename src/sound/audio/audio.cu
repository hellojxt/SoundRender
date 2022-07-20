#include "audio.h"

namespace SoundRender
{
    float AudioWapper::CallbackForSound(AudioWapper* audio)
    {
        return audio->_CallbackForSound();
    }

    float AudioWapper::_CallbackForSound()
    {
        // std::ofstream fout("/home/jiaming/Self/output/test.txt", std::ios_base::app);
        auto& modalInfos = modalSound->modalInfos;

        float soundResult = 0.0f;
        for (auto &modalInfo : modalInfos)
        {
            const auto [p, q] = modalSound->GetModalResult(modalInfo);
            soundResult += p * q;
        }
        // fout << std::endl << "***********************************" << std::endl;
        return soundResult;
    }
}