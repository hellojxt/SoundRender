#pragma once

#include "macro.h"
#include "modal.h"
#include "helper_math.h"
#include "portaudio.h"

namespace SoundRender
{

#define SAMPLE_RATE (44100)
#define FRAMES_PER_BUFFER (64)
#define TABLE_SIZE (4096)
#define DELTA_SAMPLE_NUM (1024)

    typedef struct
    {
        float signal[TABLE_SIZE];
        long int left_phase;
        long int right_phase;
        long int update_phase;
    } paSoundData;

    

    class AudioWapper
    {
    public:
        ModalSound *modalSound;
        PaStreamParameters outputParameters;
        PaStream *stream;
        PaError err;
        paSoundData data;
        long int last_phase;

        AudioWapper();
        void init()
        {
            LOG("Write AudioWapper init here");
            last_phase = -1;
        }

        void link_modal(ModalSound *modal)
        {
            modalSound = modal;
        }

        void update();

        void close();
    };
}