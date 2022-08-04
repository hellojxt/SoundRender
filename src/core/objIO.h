#pragma once

#include "array.h"
#include <string>

namespace SoundRender{

    class Mesh{
    public:
        CArr<float3> vertices;
        CArr<int3> triangles; 
        CArr<int3> tex_triangles;
		CArr<float3> vertex_texcoords;
        CArr<float3> normal;
        CArr<int3> norm_triangles;
        Mesh(CArr<float3> vertices_, CArr<int3> triangles_);
        Mesh(CArr<float3> vertices_, CArr<int3> triangles_, CArr<float3> normal_);
        Mesh(CArr<float3> vertices_, CArr<int3> triangles_, CArr<float3> tex_, CArr<int3> tex_triangles_);
        Mesh(CArr<float3> vertices_, CArr<int3> triangles_, CArr<float3> tex_, CArr<int3> tex_triangles_, CArr<float3> norms_, CArr<int3> norm_tris_);
        void print();
        void writeOBJ(std::string filename);
    };

	Mesh loadOBJ(std::string file_name, bool log = false);

}
