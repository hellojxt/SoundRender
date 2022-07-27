#include "audio.h"

namespace SoundRender
{
    
    static int patestCallback(const void *inputBuffer, void *outputBuffer,
                              unsigned long framesPerBuffer,
                              const PaStreamCallbackTimeInfo *timeInfo,
                              PaStreamCallbackFlags statusFlags,
                              void *userData)
    {
        paSoundData *data = (paSoundData *)userData;
        float *out = (float *)outputBuffer;
        for (int i = 0; i < framesPerBuffer; i++)
        {
            auto left_phase = data->left_phase % TABLE_SIZE;
            auto right_phase = data->right_phase % TABLE_SIZE;
            *out++ = data->signal[left_phase];
            *out++ = data->signal[right_phase]; /* right */
            data->left_phase++;
            data->right_phase++;
            data->signal[left_phase] = 0;
        }

        return paContinue;
    }
    AudioWapper::AudioWapper()
    {
        for (int i = 0; i < TABLE_SIZE; i++)
        {
            data.signal[i] = 0;
        }
        data.left_phase = data.right_phase = data.update_phase = 0;
        err = Pa_Initialize();
        if (err != paNoError)
        {
            printf("PortAudio error: %s\n", Pa_GetErrorText(err));
            return;
        }

        outputParameters.device = Pa_GetDefaultOutputDevice(); /* default output device */
        outputParameters.channelCount = 2;                     /* stereo output */
        outputParameters.sampleFormat = paFloat32;             /* 32 bit floating point output */
        outputParameters.suggestedLatency = Pa_GetDeviceInfo(outputParameters.device)->defaultLowOutputLatency;
        outputParameters.hostApiSpecificStreamInfo = NULL;

        err = Pa_OpenStream(
            &stream,
            NULL, /* no input */
            &outputParameters,
            SAMPLE_RATE,
            FRAMES_PER_BUFFER,
            paClipOff, /* we won't output out of range samples so don't bother clipping them */
            patestCallback,
            &data);
        if (err != paNoError)
        {
            printf("PortAudio error: %s\n", Pa_GetErrorText(err));
            return;
        }

        err = Pa_StartStream(stream);
        if (err != paNoError)
        {
            printf("PortAudio error: %s\n", Pa_GetErrorText(err));
            return;
        }
    }

    void AudioWapper::update()
    {
        ImGui::Text("Here is AudioWapper Module");

        float left_phase = data.left_phase;
        ImGui::Text("delta_phase: %d", (int)(data.update_phase - left_phase));
        ImGui::Text("TABLE_SIZE: %d", TABLE_SIZE);

        const char* items[] = { "Ceramic ", "Glass", "Wood", "Plastic", "Iron", "Polycarbonate", "Steel", "Tin"};
        static int item_current_idx = 0; // Here we store our selection data as an index.
        if (ImGui::BeginListBox("listbox 1"))
        {
            for (int n = 0; n < IM_ARRAYSIZE(items); n++)
            {
                const bool is_selected = (item_current_idx == n);
                if (ImGui::Selectable(items[n], is_selected))
                    item_current_idx = n;

                // Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                if (is_selected)
                    ImGui::SetItemDefaultFocus();
            }
            ImGui::EndListBox();
        }
        modalSound->SetMaterial( item_current_idx );
        int sample_num;
        if (last_phase == -1)
        {
            auto fps = ImGui::GetIO().Framerate;
            data.update_phase = left_phase + DELTA_SAMPLE_NUM / 2;
            sample_num = (int)(1 / fps * SAMPLE_RATE);
        }
        else
        {
            sample_num = left_phase - last_phase;
        }
        last_phase = left_phase;

        float scale_factor = (2 * M_PI * 3000) * (2 * M_PI * 3000);
        for (auto &modalInfo : modalSound->modalInfos)
        {
            float ffat_factor = modalSound->GetFFATFactor(modalInfo) * 10000;
            float q1 = modalInfo.q1;
            float q2 = modalInfo.q2;
            float f = modalInfo.f;
            float c1 = modalInfo.coeff1;
            float c2 = modalInfo.coeff2;
            float c3 = modalInfo.coeff3;
            for (int i = 0; i < sample_num; i++)
            {
                float q = c1 * q1 + c2 * q2 + c3 * f;
                q2 = q1;
                q1 = q;
                f = f * 0.2;
                data.signal[(data.update_phase + i) % TABLE_SIZE] += q * ffat_factor * scale_factor;
            }
            modalInfo.q1 = q1;
            modalInfo.q2 = q2;
            modalInfo.f = f;
        }
        if (modalSound->click_current_frame)
        {
            for (int i = 0; i < signalPlotData.size; i++)
            {
                signalPlotData.y[i] = data.signal[(data.update_phase + i - 100) % TABLE_SIZE];
            }
            modalSound->click_current_frame = false;
        }
        if (ImPlot::BeginPlot("Audio Click Signal"))
        {
            ImPlot::PlotLine("signal", signalPlotData.x, signalPlotData.y, signalPlotData.size);
            ImPlot::EndPlot();
        }

        data.update_phase = data.update_phase + sample_num;
    }

    void AudioWapper::close()
    {
        auto err = Pa_StopStream(stream);
        if (err != paNoError)
        {
            printf("PortAudio error: %s\n", Pa_GetErrorText(err));
            return;
        }
        err = Pa_CloseStream(stream);
        if (err != paNoError)
        {
            printf("PortAudio error: %s\n", Pa_GetErrorText(err));
            return;
        }
        err = Pa_Terminate();
        if (err != paNoError)
        {
            printf("PortAudio error: %s\n", Pa_GetErrorText(err));
        }
    }
}