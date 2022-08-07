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


        static int item_current_idx = 0; // Here we store our selection data as an index.
        if (ImGui::BeginListBox("Material List:\n"))
        {
            for (int n = 0; n < IM_ARRAYSIZE(MaterialConst::names); n++)
            {
                const bool is_selected = (item_current_idx == n);
                if (ImGui::Selectable(MaterialConst::names[n].c_str(), is_selected))
                {
                    if (item_current_idx != n)
                    {
                        item_current_idx = n;
                        modalSound->init(modalSound->filename, item_current_idx);
                        modalSound->SetMaterial(item_current_idx, true);
                    }
                    
                }
                // Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
                if (is_selected)
                    ImGui::SetItemDefaultFocus();
            }
            ImGui::EndListBox();
        }


        int sample_num;
        if (last_phase == -1)
        {
            auto fps = ImGui::GetIO().Framerate;
            data.update_phase = left_phase + DELTA_SAMPLE_NUM *1.5;
            sample_num = (int)(1 / fps * SAMPLE_RATE);
        }
        else
        {
            sample_num = left_phase - last_phase;
        }
        last_phase = left_phase;

        if (modalSound->click_current_frame)
        {
            float scale_factor = Correction::soundScale;
            for (auto &modalInfo : modalSound->modalInfos)
            {
                float ffat_factor = modalSound->GetFFATFactor(modalInfo) * 10000;
                float q1 = modalInfo.q1;
                float q2 = modalInfo.q2;
                float f = modalInfo.f;
                float c1 = modalInfo.coeff1;
                float c2 = modalInfo.coeff2;
                float c3 = modalInfo.coeff3;

                if (abs(q1 * ffat_factor * scale_factor) < 1e-3 && abs(q2 * ffat_factor * scale_factor) < 1e-3 && f < 1e-3)
                {
                    continue;
                }

                for (int i = 0; i < sample_num; i++)
                {
                    float q = c1 * q1 + c2 * q2 + c3 * f;
                    q2 = q1;
                    q1 = q;
                    f = f * 0.1;
                    data.signal[(data.update_phase + i) % TABLE_SIZE] += q * ffat_factor * scale_factor;
                }
                modalInfo.q1 = q1;
                modalInfo.q2 = q2;
                modalInfo.f = f;
            }
        
            for (int i = 0; i < signalPlotData.size; i++)
            {
                signalPlotData.y[i] = data.signal[(data.update_phase + i - 100) % TABLE_SIZE];
            }
            modalSound->click_current_frame = false;
        }
        data.update_phase = data.update_phase + sample_num;
        

        // plot the sound wave
        if (ImPlot::BeginPlot("Audio Click Signal"))
        {
            ImPlot::PlotLine("signal", signalPlotData.x, signalPlotData.y, signalPlotData.size);
            ImPlot::EndPlot();
        }
        //end of plotting sound wave

        // plot the FFAT map
        static ImPlotColormap map = ImPlotColormap_Viridis;
        ImPlot::PushColormap(map);
        static int modal_index = 0;
        ImGui::SliderInt("modal index", &modal_index, 0, 19);
 
        // const int plotRowNum = (int)modalSound->modalInfos[0].ffat.size();
        // const int plotColNum = (int)modalSound->modalInfos[0].ffat[0].size();
        // static double values[RowNum][ColNum];
        const int plotRowNum = 64, plotColNum = 32;
        static double values[plotRowNum][plotColNum];

        //get current theta & phi , which correspond with current row & col in ffat map 
        auto campos = modalSound->mesh_render->camera.Position * Correction::camScale;
        const float camx = campos[0], camy = campos[1], camz = campos[2];

        const float r = glm::length(campos) + 1e-4f; // to prevent singular point.
        const size_t ffatRowNum = modalSound->modalInfos[0].ffat.size();
        const size_t ffatColNum = modalSound->modalInfos[0].ffat[0].size();
        const float rowSampleIntervalRep = ffatRowNum / (2 * PI);
        const float colSampleIntervalRep = ffatColNum / PI;

        float theta = std::acos(camz / r);
        float phi = camy <= 1e-5f && camx <= 1e-5f && camx >= -1e-5f && camy >= -1e-5f ? 0.0f : std::fmod(std::atan2(camy, camx) + 2 * PI, 2 * PI);

        float colInter = theta * colSampleIntervalRep, rowInter = phi * rowSampleIntervalRep;
        int col = static_cast<int>(colInter);
        int row = static_cast<int>(rowInter);

        int ffat_i=0,ffat_j=0;
        for (int i = 0; i < plotRowNum; i++)
        {
            for (int j = 0; j < plotColNum; j++)
            {
                //always put the coordinate (theta,phi) in the center of the FFAT map
                ffat_i=(i+plotRowNum/2-row+plotRowNum)%plotRowNum;
                ffat_j=(j+plotColNum/2-col+plotColNum)%plotColNum;
                values[i][j] = modalSound->modalInfos[modal_index].ffat[ffat_i][ffat_j];
            }
        }

        static float scale_min = 0;
        static float scale_max = 0.001f;
        ImGui::SetNextItemWidth(225);
        ImGui::DragFloatRange2("Min / Max", &scale_min, &scale_max, 0.001f, 0, 1);

        if (ImPlot::BeginPlot("##Heatmap",ImVec2(225,450)))
        {
          
            ImPlot::SetupAxes(NULL, NULL, ImPlotAxisFlags_NoDecorations, ImPlotAxisFlags_NoDecorations);
            ImPlot::PlotHeatmap("ffat map", values[0],plotRowNum, plotColNum, scale_min, scale_max, NULL);
            ImPlot::EndPlot();
        }
        ImGui::SameLine();
        ImPlot::ColormapScale("##HeatScale", scale_min, scale_max, ImVec2(60, 225));
        ImPlot::PopColormap();
        // end of plotting FFAT map


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