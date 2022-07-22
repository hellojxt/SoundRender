#include "modal.h"
#include <queue>
#include <unordered_map>
#include <mutex>
#include <algorithm>
namespace SoundRender
{
    float3 GetTriangleCenter(int3 tri, CArr<float3> &vertArr)
    {
        return (vertArr[tri.x] + vertArr[tri.y] + vertArr[tri.z]) / 3.0f;
    }

    float3 GetTriangleNormal(int3 tri, CArr<float3> &vertArr)
    {
        float3 e1 = vertArr[tri.x] - vertArr[tri.y], e2 = vertArr[tri.y] - vertArr[tri.z];
        return normalize(cross(e1, e2));
    }

    ModalInfo::ModalInfo(float lambda, size_t index, cnpy::NpyArray &eigenVecs, cnpy::NpyArray &ffats)
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
        coeff2 = -sqrEpsilon;

        float coeff3_item1 = epsilon * std::cos(theta + gamma);
        float coeff3_item2 = sqrEpsilon * std::cos(2 * theta + gamma);
        coeff3 = 2 * (coeff3_item1 - coeff3_item2) / (3 * omega * omega_prime);

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
        f = q1 = q2 = 0;
    }

    void ModalSound::init(const char *eigenPath, const char *ffatPath, const char *voxelPath)
    {
        cnpy::npz_t eigenData = cnpy::npz_load(eigenPath);
        cnpy::NpyArray &rawEigenValues = eigenData["vals"];                 // get S
        cnpy::NpyArray &rawEigenVecs = eigenData["vecs"];                   // get U
        cnpy::NpyArray rawFFAT = cnpy::npz_load(ffatPath, "feats_out_far"); // get FFAT.
        assert(rawFFAT.word_size == sizeof(double));
        assert(rawEigenValues.word_size == sizeof(float));
        assert(rawEigenVecs.word_size == sizeof(float));

        FillModalInfos(rawEigenValues, rawEigenVecs, rawFFAT);
        cnpy::NpyArray rawVoxelData = cnpy::npy_load(voxelPath);
        assert(rawVoxelData.word_size == sizeof(int));
        FillVertID(rawVoxelData);
        select_voxel_idx = make_int3(-1, -1, -1);
        select_point = make_float3(-1, -1, -1);
        force = 0.5;
        for (int i = 0; i < 8; i++)
        {
            select_voxel_vertex_idx[i] = -1;
        }
    }

    void ModalSound::update()
    {
        ImGui::Text("Here is ModalSound Module");
        ImGui::Text("Mesh has %d vertices and %d triangles", mesh_render->vertices.size(), mesh_render->triangles.size());
        ImGui::Text("Camera position:  (%f, %f, %f)", mesh_render->camera.Position.x, mesh_render->camera.Position.y, mesh_render->camera.Position.z);
        ImGui::SliderFloat("Click Force", &force, 0.0f, 1.0f);
        ImGui::Text("Force: %f", force);
        ImGui::Text("Selected Triangle Index: %d", mesh_render->selectedTriangle);
        reset_modal_f();
        if (mesh_render->soundNeedsUpdate)
        {
            int3 tri = mesh_render->triangles[mesh_render->selectedTriangle];
            select_point = GetTriangleCenter(tri, mesh_render->vertices);
            select_voxel_idx = GetNormalizedID(select_point);
            auto norm = GetTriangleNormal(tri, mesh_render->vertices);
            for (int i = 0; i < 8; i++)
            {
                auto offset = MaterialConst::offsets[i];
                auto id = vertData[select_voxel_idx.x + offset[0]][select_voxel_idx.y + offset[1]][select_voxel_idx.z + offset[2]] * 3;
                select_voxel_vertex_idx[i] = id;
                for (auto &modalInfo : modalInfos)
                {
                    auto mode_f = modalInfo.eigenVec[id] * norm.x + modalInfo.eigenVec[id + 1] * norm.y + modalInfo.eigenVec[id + 2] * norm.z;
                    modalInfo.f += mode_f * force / 8;
                }
            }
            mesh_render->soundNeedsUpdate = false;
        }
        ImGui::Text("Selected Triangle Center: (%f, %f, %f)", select_point.x, select_point.y, select_point.z);
        ImGui::Text("Selected Voxel Index: (%d, %d, %d)", select_voxel_idx.x, select_voxel_idx.y, select_voxel_idx.z);
        ImGui::Text("Selected Voxel Vertex Index: ");
        for (int i = 0; i < 8; i++)
        {
            ImGui::Text("%d", select_voxel_vertex_idx[i]);
        }
    }

    int3 ModalSound::GetNormalizedID(float3 center)
    {
        size_t voxelNum = vertData.size() - 1;
        float3 bbMin = mesh_render->bbox_min, bbMax = mesh_render->bbox_max;
        float3 relative_coord = (center - bbMin) / (bbMax - bbMin);
        return make_int3((relative_coord * (float)voxelNum));
    }

    void ModalSound::FillModalInfos(cnpy::NpyArray &rawEigenValues, cnpy::NpyArray &rawEigenVecs, cnpy::NpyArray &rawFFAT)
    {
        size_t selectNum = rawFFAT.shape[0];
        modalInfos.reserve(selectNum);
        float *valueData = rawEigenValues.data<float>();
        for (int i = 0; i < selectNum; i++)
        {
            modalInfos.emplace_back(valueData[i], i, rawEigenVecs, rawFFAT);
        }
        return;
    }

    void ModalSound::FillVertID(cnpy::NpyArray &rawVoxelData)
    {
        int *voxelData = rawVoxelData.data<int>();
        size_t xSize = rawVoxelData.shape[0], ySize = rawVoxelData.shape[1],
               zSize = rawVoxelData.shape[2];

        // allocate memory.
        vertData.resize(xSize + 1);
        for (auto &i : vertData)
        {
            i.resize(ySize + 1);
            for (auto &j : i)
            {
                j.resize(zSize + 1, 0);
            }
        }

        // check voxel in object.
        for (size_t i = 0; i < xSize; i++)
        {
            size_t baseIndex1 = i * ySize * zSize;
            for (size_t j = 0; j < ySize; j++)
            {
                size_t baseIndex = j * zSize + baseIndex1;
                for (size_t k = 0; k < zSize; k++)
                {
                    if (voxelData[baseIndex + k] == 1)
                    {
                        for (auto &offset : MaterialConst::offsets)
                        {
                            vertData[i + offset[0]][j + offset[1]][k + offset[2]] = 1;
                        }
                    }
                }
            }
        }

        // put id in vert bucket.
        int cnt = 0;
        for (auto &i : vertData)
        {
            for (auto &j : i)
            {
                for (int &k : j)
                {
                    if (k == 1)
                    {
                        k = cnt;
                        ++cnt;
                    }
                }
            }
        }
        return;
    }

    inline float Lerp(float x1, float x2, float coeff)
    {
        return x1 * coeff + x2 * (1 - coeff);
    }

    float ModalSound::GetFFATFactor(ModalInfo& modalInfo)
    {
        const float camx = mesh_render->camera.Position[0],
            camy = mesh_render->camera.Position[1],
            camz = mesh_render->camera.Position[2];
        const float r = std::sqrt(camx * camx + camy * camy + camz * camz) + 1e-4f; // to prevent singular point.
        const size_t ffatRowNum = modalInfo.ffat.size();
        const size_t ffatColNum = modalInfo.ffat[0].size();
        // Here we need row and col sample intervals are the same, otherwise changes are needed.
        const float rowSampleIntervalRep = ffatRowNum / (2 * PI);
        const float colSampleIntervalRep = ffatColNum / PI;

        float theta = std::acos(camz / r);
        float phi = camy <= 1e-5f && camx <= 1e-5f && camx >= -1e-5f && camy >= -1e-5f ? 0.0f : std::fmod(std::atan2(camy, camx) + 2 * PI, 2* PI);

        float colInter = theta * colSampleIntervalRep, rowInter = phi * rowSampleIntervalRep;
        int col = static_cast<int>(colInter);
        float colFrac = colInter - static_cast<float>(col);
        int row = static_cast<int>(rowInter);
        float rowFrac = rowInter - static_cast<float>(row);
        // bi-Lerp.
        int nextRow = (row + 1) % ffatRowNum, nextCol = (col + 1) % ffatColNum;
        float interResult = Lerp(Lerp(modalInfo.ffat[row][col], modalInfo.ffat[nextRow][col], rowFrac),
                                 Lerp(modalInfo.ffat[row][nextCol], modalInfo.ffat[nextRow][nextCol], rowFrac), colFrac);

        // printf("camx = %f, camy = %f, camz = %f, ffatColNum = %zu, theta = %f, phi = %f, colInter = %f, col = %d, rowInter = %f,"
        // "row = %d, modalInfo.ffat : [row][col] = %f, [row+1][col] = %f, [row][col+1]=%f, [row+1][col+1]=%f, interResult = %f\n",
        // camx, camy, camz, ffatColNum, theta, phi, colInter, col, rowInter, row, modalInfo.ffat[row][col], modalInfo.ffat[row+1][col],
        // modalInfo.ffat[row][col+1],modalInfo.ffat[row+1][col+1], interResult);

        return interResult / r;
    }
}