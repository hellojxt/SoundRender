#include "gui.h"
#include "window.h"
#include "objIO.h"
#include "audio_window.h"
#include <math.h>
#include <filesystem>
using namespace SoundRender;

void Preprocess()
{
#ifdef _WIN32
    const wchar_t* meshRelaPath = L"asset/meshes";
    const wchar_t* correctionRelaPath = L"asset/correction";
    const wchar_t* fileName = L"correction.txt";
#else
    const char* meshRelaPath = "asset/meshes";
    const char* correctionRelaPath = "asset/correction";
    const char* fileName = "correction.txt";
#endif

    const auto rootPath =  std::filesystem::current_path().parent_path();
    const auto meshPath = rootPath / meshRelaPath;
    const auto correctionPath = rootPath / correctionRelaPath;
    if(!std::filesystem::exists(correctionPath))
        std::filesystem::create_directory(correctionPath);
    ModalSound::PreprocessAllModals(meshPath, correctionPath / fileName);    
    return;
}

int main()
{
    Preprocess();
    auto filename = std::string(ASSET_DIR) + std::string("/meshes/plate.obj");
    auto mesh = loadOBJ(filename, true);
    GUI gui;
    MeshRender render;
    render.load_mesh(mesh.vertices, mesh.triangles, mesh.vertex_texcoords, mesh.tex_triangles);
    render.SetShaderPara(mesh);
    gui.add_window(&render);
    AudioWindow audio_window(filename);
    audio_window.link_mesh_render(&render);
    gui.add_window(&audio_window);
    gui.start();
    return 0;
}
