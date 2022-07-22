#pragma once

#include "macro.h"
#include "window.h"
#include "cnpy.h"
#include "helper_math.h"

namespace SoundRender
{
    namespace MaterialConst
    {
        constexpr float alpha = 60.0f;
        constexpr float beta = 2e-6f;
        constexpr float timestep = 1.0f / 44100;

        constexpr int offsets[][3] = {
            {0, 0, 0}, {1, 0, 0}, {1, 1, 0}, {0, 1, 0}, {0, 0, 1}, {1, 0, 1}, {1, 1, 1}, {0, 1, 1}};
    }

    struct ModalInfo
    {
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
        void init(const char *eigenPath, const char *ffatPath, const char *voxelPath);

        void link_mesh_render(MeshRender *mesh_render)
        {
            this->mesh_render = mesh_render;
        }

        void reset_modal_f()
        {
            for (auto &modal : modalInfos)
            {
                modal.f = 0;
            }
        }

        void update();
        std::vector<ModalInfo> modalInfos;
        std::vector<std::vector<std::vector<int>>> vertData;
        int3 GetNormalizedID(float3 center);
        float GetFFATFactor(ModalInfo&);

    private:
        void FillModalInfos(cnpy::NpyArray &rawEigenValues, cnpy::NpyArray &rawEigenVecs, cnpy::NpyArray &rawFFAT);
        void FillVertID(cnpy::NpyArray &rawVoxelData);
    };
}