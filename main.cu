#include "gui.h"
#include "window.h"
#include "objIO.h"
#include "audio_window.h"
#include <math.h>
#include <filesystem>
using namespace SoundRender;
void Preprocess()
{
    const std::string fileName = "/correction.txt";
    std::string assetPath{ ASSET_DIR };
    std::string meshPath = std::string(ASSET_DIR) + "/meshes";
    std::string correctionPath = std::string(ASSET_DIR) + "/correction";
    if (!std::filesystem::exists(correctionPath))
      std::filesystem::create_directory(correctionPath);
    ModalSound::PreprocessAllModals(meshPath, correctionPath + fileName);
    return;
}

int main()
{
    Preprocess();
    GUI gui;
    MeshRender render;
    gui.add_window(&render);
    AudioWindow audio_window;
    audio_window.link_mesh_render(&render);
    gui.add_window(&audio_window);
    gui.start();
    return 0;
}
