#pragma once
#include "array.h"
#include <string>

namespace SoundRender{

    struct Mesh{
        CArr<float3> vertices;
        CArr<int3> triangles; 
        CArr<float3> normal;
        Mesh(CArr<float3> vertices_, CArr<int3> triangles_);
        Mesh(CArr<float3> vertices_, CArr<int3> triangles_, CArr<float3> normal_);
        void print();
        void writeOBJ(std::string filename);
    };

    Mesh loadOBJ(const char* file_name);

}

#include "objIO.inl"