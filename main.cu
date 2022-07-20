#include "gui.h"
#include "window.h"
#include "objIO.h"
#include "audio_window.h"
#include "portaudio.h"
#include <math.h>
using namespace SoundRender;


#define SAMPLE_RATE   (44100)
#define FRAMES_PER_BUFFER  (64)
#ifndef M_PI
#define M_PI  (3.14159265)
#endif
#define TABLE_SIZE (200)

//test mode on: play sine wave while the GUI window is open
//test mode off: work as the sound renderer
// #define test

#ifdef test
typedef struct
{
    float sine[TABLE_SIZE];
    int left_phase;
    int right_phase;
}
paSoundData;

#else
struct paSoundData
{
    AudioWapper* aw;

    paSoundData(AudioWapper* another) :aw(another) {};
};
#endif

static int patestCallback(const void* inputBuffer, void* outputBuffer,
    unsigned long framesPerBuffer,
    const PaStreamCallbackTimeInfo* timeInfo,
    PaStreamCallbackFlags statusFlags,
    void* userData)
{
    paSoundData* data = (paSoundData*)userData;
    float* out = (float*)outputBuffer;
    unsigned long i;

    (void) timeInfo; /* Prevent unused variable warnings. */
    (void) statusFlags;
    (void) inputBuffer;

    for (i = 0; i < framesPerBuffer; i++)
    {
#ifdef test
        *out++ = data->sine[data->left_phase];  /* left */
        *out++ = data->sine[data->right_phase];  /* right */
        data->left_phase += 1;
        if (data->left_phase >= TABLE_SIZE) data->left_phase -= TABLE_SIZE;
        data->right_phase += 1;
        if (data->right_phase >= TABLE_SIZE) data->right_phase -= TABLE_SIZE;
#else
        float sound = AudioWapper::CallbackForSound(data->aw);
        *out++ = sound;  /* left */
        *out++ = sound;  /* right */
#endif

    }

    return paContinue;
}



int main()
{
    auto filename = std::string(ASSET_DIR) + std::string("/meshes/bunny.obj");
    auto mesh = loadOBJ(filename, true);
    GUI gui;
    MeshRender render;
    AudioWindow audio_window;
    render.load_mesh(mesh.vertices, mesh.triangles);
    audio_window.link_mesh_render(&render);
    gui.add_window(&render);
    gui.add_window(&audio_window);


    //==========portaudio====================
    PaStreamParameters outputParameters;
    PaStream* stream;
    PaError err;

   


#ifdef test
    paSoundData data;
    int i;

    for (i = 0; i < TABLE_SIZE; i++)
    {
        data.sine[i] = sin(((double)i / TABLE_SIZE) * M_PI * 2.0 ) ;
    }
    data.left_phase = data.right_phase = 0;
#else

    paSoundData data=paSoundData(&audio_window.audio);
#endif
  

    err=Pa_Initialize();
    if (err != paNoError) goto error;

    outputParameters.device = Pa_GetDefaultOutputDevice(); /* default output device */
    outputParameters.channelCount = 2;       /* stereo output */
    outputParameters.sampleFormat = paFloat32; /* 32 bit floating point output */
    outputParameters.suggestedLatency = Pa_GetDeviceInfo(outputParameters.device)->defaultLowOutputLatency;
    outputParameters.hostApiSpecificStreamInfo = NULL;

    err = Pa_OpenStream(
        &stream,
        NULL, /* no input */
        &outputParameters,
        SAMPLE_RATE,
        FRAMES_PER_BUFFER,
        paClipOff,      /* we won't output out of range samples so don't bother clipping them */
        patestCallback,
        &data);
    if (err != paNoError) goto error;
   
    err = Pa_StartStream(stream);
    if (err != paNoError) goto error;
    //==========portaudio====================
    
    gui.start();


    //==========portaudio====================
    err = Pa_StopStream(stream);
    if (err != paNoError) goto error;
    err = Pa_CloseStream(stream);
    if (err != paNoError) goto error;
    err = Pa_Terminate();
    if (err != paNoError) goto error;
    //==========portaudio====================

    return 0;

error:
    Pa_Terminate();
    fprintf(stderr, "An error occurred while using the portaudio stream\n");
    fprintf(stderr, "Error number: %d\n", err);
    fprintf(stderr, "Error message: %s\n", Pa_GetErrorText(err));
    return 0;
}













