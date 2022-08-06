#pragma once

#include "macro.h"
#include "window.h"
#include "cnpy.h"
#include "helper_math.h"
#include "array3D.h"
#define M_PI (3.1415926)
#include <filesystem>
#include <unordered_map>
#include <string>

namespace SoundRender
{
    namespace Correction
    {
        extern float camScale;
        extern float soundScale;
        extern std::unordered_map<std::string, float> allSoundScales;
    }

    namespace MaterialConst
    {
        // Ceramic, Glass, Wood, Plastic, Iron, Steel, Tin.
        static std::string names[] = {"Ceramic", "Glass", "Wood", "Plastic", "Iron", "Steel", "Tin" };
        constexpr float alpha[] = {6.0f, 1.0f, 60.0f, 30.0f, 5.0f, 5.0f, 2.0f};
        constexpr float beta[] = {1e-7f, 1e-7f, 2e-6f, 1e-6f, 1e-7f, 3e-8f, 3e-8f};
        constexpr float timestep = 1.0f / 44100;
        constexpr int offsets[][3] = {
            {0, 0, 0}, {1, 0, 0}, {1, 1, 0}, {0, 1, 0}, {0, 0, 1}, {1, 0, 1}, {1, 1, 1}, {0, 1, 1}};
    };

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
        void SetMaterial(int chosenID);
    private:
        float eigenVal;
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
        std::string filename;
        void init(const std::string& modalName, int materialID);

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
        void SetMaterial(int chosenID);
        void SetModal(const char *eigenPath, const char *ffatPath, const char *voxelPath);
        static void PreprocessAllModals(const std::filesystem::path& meshRootPath, const std::filesystem::path& scaleFilePath);
    private:
        void FillModalInfos(cnpy::NpyArray &rawEigenValues, cnpy::NpyArray &rawEigenVecs, cnpy::NpyArray &rawFFAT);
        void FillVertID(cnpy::NpyArray &rawVoxelData);
        void AdjustSoundScale();
    };
}