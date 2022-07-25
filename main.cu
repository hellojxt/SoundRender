#include "gui.h"
#include "window.h"
#include "objIO.h"
#include "audio_window.h"
#include <math.h>
using namespace SoundRender;

int main()
{
    auto filename = std::string(ASSET_DIR) + std::string("/meshes/plate.obj");
    auto mesh = loadOBJ(filename, true);
    GUI gui;
    MeshRender render;
    render.load_mesh(mesh.vertices, mesh.triangles);
    gui.add_window(&render);
    AudioWindow audio_window(filename);
    audio_window.link_mesh_render(&render);
    gui.add_window(&audio_window);
    gui.start();
    return 0;
}
