#pragma once

#include "macro.h"
#include "window.h"

#include "cnpy.h"
#include <unordered_map>
#include <mutex>
#include <algorithm>

namespace SoundRender
{
    namespace MaterialConst
    {
        constexpr float alpha = 60.0f;
        constexpr float beta = 2e-6f;
        constexpr float timestep = 1.0f / 44100;

        constexpr int offsets[][3] = {
            {0,0,0},{1,0,0},
            {1,1,0},{0,1,0},
            {0,0,1},{1,0,1},
            {1,1,1},{0,1,1}
        };
    }

    struct ModalInfo
    {
        float coeff1;
        float q1;
        float coeff2;
        float q2;
        float coeff3;
        float f;
        std::vector<float> eigenVec;
        std::vector<std::vector<double>> ffat;
        ModalInfo(float lambda, size_t index, cnpy::NpyArray &eigenVecs, cnpy::NpyArray &ffats)
        {
            using namespace MaterialConst;
            float omega = std::sqrt(lambda);
            float ksi = (alpha + beta * lambda) / (2 * omega);
            float omega_prime = omega * std::sqrt(1 - ksi * ksi);
            float epsilon = std::exp(-ksi * omega * timestep);
            float sqrEpsilon = epsilon * epsilon;
            float theta = omega_prime * timestep;
            float gamma = std::asin(ksi);

            coeff1 = 2 * epsilon * std::cos(theta);
            coeff2 = sqrEpsilon;

            float coeff3_item1 = epsilon * std::cos(theta + gamma);
            float coeff3_item2 = sqrEpsilon * std::cos(2 * theta + gamma);
            coeff3 = 2 * (coeff3_item1 - coeff3_item2) / (3 * omega * omega_prime);

            q1 = q2 = f = 0.0;

            size_t rank = eigenVecs.shape[0], colNum = eigenVecs.shape[1];
            eigenVec.reserve(rank);
            float *eigenVecsData = eigenVecs.data<float>();
            for (size_t i = 0; i < rank; i++)
            {
                eigenVec.push_back(eigenVecsData[i * colNum + index]);
            }

            size_t ffatRowNum = ffats.shape[1], ffatColNum = ffats.shape[2];
            double *ffatsData = ffats.data<double>() + ffatRowNum * ffatColNum * index;
            ffat.reserve(ffatRowNum);
            for (size_t i = 0; i < ffatRowNum; i++)
            {
                size_t baseIndex = i * ffatColNum;
                ffat.emplace_back(ffatsData + baseIndex, ffatsData + baseIndex + ffatColNum);
            }
            return;
        }
    };

    class ModalSound
    {
    public:
        float force;
        bool soundNeedUpdate = false;
        MeshRender *mesh_render;
        void init(const char* eigenPath, const char* ffatPath, const char* voxelPath)
        {
            cnpy::npz_t eigenData = cnpy::npz_load(eigenPath);

            cnpy::NpyArray& rawEigenValues = eigenData["vals"]; // get S
            cnpy::NpyArray& rawEigenVecs = eigenData["vecs"]; // get U
            cnpy::NpyArray rawFFAT = cnpy::npz_load(ffatPath, "feats_out_far"); // get FFAT.

            assert(rawFFAT.word_size == sizeof(double));
            assert(rawEigenValues.word_size == sizeof(float));
            assert(rawEigenVecs.word_size == sizeof(float));
            //FilterAndFillModalInfos(rawEigenValues, rawEigenVecs, rawFFAT);
            FillModalInfos(rawEigenValues, rawEigenVecs, rawFFAT);
            FillBoundingBoxData();

            cnpy::NpyArray rawVoxelData = cnpy::npy_load(voxelPath);
            assert(rawVoxelData.word_size == sizeof(int));
            FillVertID(rawVoxelData);
            return;
        }

        void link_mesh_render(MeshRender *mesh_render)
        {
            this->mesh_render = mesh_render;
        }

        void update()
        {
            ImGui::Text("Here is ModalSound Module");
            ImGui::Text("Mesh has %d vertices and %d triangles", mesh_render->vertices.size(), mesh_render->triangles.size());
            ImGui::Text("Camera position:  (%f, %f, %f)", mesh_render->camera.Position.x, mesh_render->camera.Position.y, mesh_render->camera.Position.z);
            ImGui::SliderFloat("Click Force", &force, 0.0f, 1.0f);
            ImGui::Text("Force: %f", force);
            ImGui::Text("Selected Triangle Index: %d", mesh_render->selectedTriangle);
            if (ImGui::IsKeyDown(ImGui::GetKeyIndex(ImGuiKey_Space)))
            {
                printf("Space key is down and click sound is synthesized\n");
                soundNeedUpdate = true;
            }
        }

        std::tuple<size_t, size_t, size_t> GetNormalizedID(float x, float y, float z)
        {
            size_t voxelNum = vertData.size() - 1;
            x -= bound[0], y-= bound[1], z-= bound[2];
            auto CoordToID = [=](float c)
            { return static_cast<size_t>((c + 0.5f) * voxelNum - 0.5f); };
            return {CoordToID(x / diff), CoordToID(y / diff), CoordToID(z / diff)};
        }


        std::vector<ModalInfo> modalInfos;
        std::vector<std::vector<std::vector<int>>> vertData;
        std::pair<float, float> GetModalResult(ModalInfo& modalInfo);
    private:
        [[deprecated("Because data have been filtered.")]]
        void FilterAndFillModalInfos(cnpy::NpyArray& rawEigenValues, cnpy::NpyArray& rawEigenVecs, cnpy::NpyArray& rawFFAT);

        void FillModalInfos(cnpy::NpyArray& rawEigenValues, cnpy::NpyArray& rawEigenVecs, cnpy::NpyArray& rawFFAT);

        void FillVertID(cnpy::NpyArray& rawVoxelData);

        void FillBoundingBoxData()
        {
            const auto& vertices = mesh_render->vertices;
            size_t vertNum = vertices.size();
            float maxBound[3] = {0}, minBound[3] = {1e5f, 1e5f, 1e5f};
            auto UpdateMinMax = [&](int j, float m){
                if(m > maxBound[j])
                    maxBound[j] = m;
                else if(m < minBound[j])
                    minBound[j] = m;
                return;
            };
            for(size_t i = 0; i < vertNum; ++i)
            {
                UpdateMinMax(0, vertices[i].x);
                UpdateMinMax(1, vertices[i].y);
                UpdateMinMax(2, vertices[i].z);
            }

            diff = std::max({maxBound[0] - minBound[0], maxBound[1] - minBound[1], maxBound[2] - minBound[2]});
            for(size_t i = 0; i < 3; ++i)
                bound[i] = (maxBound[i] + minBound[i]) / 2;

            return;
        }
        float diff;
        float bound[3];
    };
}