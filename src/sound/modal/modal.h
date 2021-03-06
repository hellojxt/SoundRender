#pragma once

#include "macro.h"
#include "window.h"
#include "cnpy.h"
#include "helper_math.h"
#include "array3D.h"

namespace SoundRender
{
    namespace MaterialConst
    {
        constexpr float alpha = 6.0f;
        constexpr float beta = 1e-7f;
        constexpr float timestep = 1.0f / 44100;

        constexpr int offsets[][3] = {
            {0, 0, 0}, {1, 0, 0}, {1, 1, 0}, {0, 1, 0}, {0, 0, 1}, {1, 0, 1}, {1, 1, 1}, {0, 1, 1}};
    }

    class ModalInfo
    {
        public:
        float coeff1;
        float coeff2;
        float coeff3;
        std::vector<float> eigenVec;
        std::vector<std::vector<double>> ffat;
        float f;
        float q1;
        float q2;
        ModalInfo(float lambda, size_t index, cnpy::NpyArray &eigenVecs, cnpy::NpyArray &ffats);
    };

    class ModalSound
    {
    public:
        float force;
        MeshRender *mesh_render;
        float3 select_point;
        int3 select_voxel_idx;
        int select_voxel_vertex_idx[8];
        bool click_current_frame;
        void init(const char *eigenPath, const char *ffatPath, const char *voxelPath);

        void link_mesh_render(MeshRender *mesh_render)
        {
            this->mesh_render = mesh_render;
        }

        void update();
        std::vector<ModalInfo> modalInfos;
        CArr3D<int> vertData;
        CArr3D<int> voxelData;
        int3 GetNormalizedID(float3 center);
        float GetFFATFactor(ModalInfo&);

    private:
        void FillModalInfos(cnpy::NpyArray &rawEigenValues, cnpy::NpyArray &rawEigenVecs, cnpy::NpyArray &rawFFAT);
        void FillVertID(cnpy::NpyArray &rawVoxelData);
    };
}