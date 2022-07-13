#include "gui.h"
#include "window.h"
#include "objIO.h"
#include "audio_window.h"
using namespace SoundRender;

int main()
{
    auto filename = std::string(ASSET_DIR) + std::string("/meshes/example.obj");
    auto mesh = loadOBJ(filename, true);
    GUI gui;
    MeshRender render;
    AudioWindow audio_window;
    render.load_mesh(mesh.vertices, mesh.triangles);
    audio_window.link_mesh_render(&render);
    gui.add_window(&render);
    gui.add_window(&audio_window);
    gui.start();
    return 0;
}