#include "modal.h"
#include "objIO.h"
#include <algorithm>

namespace SoundRender
{
    namespace Correction
    {
        float camScale = 0.0f;
        float soundScale = 0.0f;

        std::unordered_map<std::string, float> allSoundScales;
    }

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
        eigenVal = lambda;
        SetMaterial(0);
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

    void ModalInfo::SetMaterial(int chosenID)
    {
        float alpha = MaterialConst::alpha[chosenID], beta = MaterialConst::beta[chosenID];
        float lambda = eigenVal;

        float omega = std::sqrt(lambda);
        float ksi = (alpha + beta * lambda) / (2 * omega);
        float omega_prime = omega * std::sqrt(1 - ksi * ksi);
        float epsilon = std::exp(-ksi * omega * MaterialConst::timestep);
        float sqrEpsilon = epsilon * epsilon;
        float theta = omega_prime * MaterialConst::timestep;
        float gamma = std::asin(ksi);

        coeff1 = 2 * epsilon * std::cos(theta);
        coeff2 = -sqrEpsilon;

        float coeff3_item1 = epsilon * std::cos(theta + gamma);
        float coeff3_item2 = sqrEpsilon * std::cos(2 * theta + gamma);
        coeff3 = 2 * (coeff3_item1 - coeff3_item2) / (3 * omega * omega_prime);
        return;
    };

    void ModalSound::init(const std::string &filename, int materialID)
    {
        this->filename = filename;
        auto pos1 = filename.rfind('/') + 1, pos2 = filename.rfind('.');
        auto modelName = filename.substr(pos1, pos2 - pos1);
        auto eigenPath = std::string(ASSET_DIR) + std::string("/eigen/") + modelName + std::string("_") + MaterialConst::names[materialID] + std::string(".npz");
        auto ffatPath = std::string(ASSET_DIR) + std::string("/acousticMap/") + modelName + std::string("_") + MaterialConst::names[materialID] + std::string(".npz");
        auto voxelPath = std::string(ASSET_DIR) + std::string("/voxel/") + modelName + std::string(".npy");
        SetModal(eigenPath.c_str(), ffatPath.c_str(), voxelPath.c_str());
        Correction::soundScale = Correction::allSoundScales[modelName];
        return;
    }

    void ModalSound::update()
    {
        ImGui::Text("Here is ModalSound Module");
        ImGui::Text("Mesh has %d vertices and %d triangles", mesh_render->vertices.size(), mesh_render->triangles.size());
        ImGui::Text("Camera position:  (%f, %f, %f)", mesh_render->camera.Position.x * Correction::camScale,
                    mesh_render->camera.Position.y * Correction::camScale, mesh_render->camera.Position.z * Correction::camScale);
        ImGui::SliderFloat("Click Force", &force, 0.0f, 1.0f);
        ImGui::Text("Force: %f", force);
        ImGui::Text("Selected Triangle Index: %d", mesh_render->selectedTriangle);
        ImGui::Text("This material & model preprocessed for %lf seconds.", preprocessTime);
        float tanHalfFov = std::tan(glm::radians(mesh_render->camera.Zoom) / 2);
        static float initTanHalfFov = tanHalfFov;
        Correction::camScale = tanHalfFov / initTanHalfFov;

        // if click or space key is pressed
        if ((mesh_render->soundNeedsUpdate || ImGui::IsKeyPressed(GLFW_KEY_SPACE)) && mesh_render->selectedTriangle != -1)
        {
            std::cout << "True2.\n";
            int3 tri = mesh_render->triangles[mesh_render->selectedTriangle];
            select_point = GetTriangleCenter(tri, mesh_render->vertices);
            auto norm = GetTriangleNormal(tri, mesh_render->vertices);
            auto y = norm.x;
            auto x = -norm.y;
            norm.x = x;
            norm.y = y;
            select_voxel_idx = GetNormalizedID(select_point);

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
            click_current_frame = true;
            mesh_render->soundNeedsUpdate = false;
        }
        ImGui::Text("Selected Triangle Center: (%f, %f, %f)", select_point.x, select_point.y, select_point.z);
        ImGui::Text("Selected Voxel Index: (%d, %d, %d)", select_voxel_idx.x, select_voxel_idx.y, select_voxel_idx.z);
        if (select_voxel_idx.x >= 0 && select_voxel_idx.y >= 0 && select_voxel_idx.z >= 0)
            ImGui::Text("Selected Voxel value: %d", voxelData(select_voxel_idx.x, select_voxel_idx.y, select_voxel_idx.z));
        ImGui::Text("Selected Voxel Vertex Index: ");
        for (int i = 0; i < 8; i++)
        {
            ImGui::Text("%d", select_voxel_vertex_idx[i]);
        }
    }

    void ModalSound::AdjustSoundScale()
    {
        float currMax = 0.0f;
        float scale_factor = (2 * M_PI * 3000) * (2 * M_PI * 3000);
        float tanHalfFov = std::tan(glm::radians(15.0f) / 2);
        float tempScale = tanHalfFov / std::tan(glm::radians(45.0f) / 2);
        std::vector<double> ffatFactors(modalInfos.size());
        for (int i = 0; i < ffatFactors.size(); i++)
        {
            double tempMax = 0.0f;
            for (auto &row : modalInfos[i].ffat)
            {
                auto temp = std::max_element(row.begin(), row.end());
                tempMax = std::max(*temp, tempMax);
            }
            ffatFactors[i] = tempMax / (4 * tempScale);
        }
            for (int i = 0; i < mesh_render->triangles.size(); i++)
            {
                int3 tri = mesh_render->triangles[i];
                select_point = GetTriangleCenter(tri, mesh_render->vertices);
                auto norm = GetTriangleNormal(tri, mesh_render->vertices);
                select_voxel_idx = GetNormalizedID(select_point);

                for (int i = 0; i < 8; i++)
                {
                    auto offset = MaterialConst::offsets[i];
                    auto id = vertData[select_voxel_idx.x + offset[0]][select_voxel_idx.y + offset[1]][select_voxel_idx.z + offset[2]] * 3;
                    select_voxel_vertex_idx[i] = id;
                    for (auto &modalInfo : modalInfos)
                    {
                        auto mode_f = modalInfo.eigenVec[id] * norm.x + modalInfo.eigenVec[id + 1] * norm.y + modalInfo.eigenVec[id + 2] * norm.z;
                        modalInfo.f += mode_f * 1.0f / 8; // force_max = 1.0f;
                    }
                }

                float result = 0.0f;
                for (int i = 0; i < modalInfos.size(); i++)
                {
                    auto &modalInfo = modalInfos[i];
                    float ffat_factor = ffatFactors[i] * 10000;
                    float q1 = modalInfo.q1;
                    float q2 = modalInfo.q2;
                    float f = modalInfo.f;
                    float c1 = modalInfo.coeff1;
                    float c2 = modalInfo.coeff2;
                    float c3 = modalInfo.coeff3;
                    float q = c1 * q1 + c2 * q2 + c3 * f;
                    modalInfo.f = 0;
                    result += q * ffat_factor * scale_factor;
                }

                if (result > currMax)
                    currMax = result;
            }
        Correction::soundScale = scale_factor / (currMax + 0.1f);
    }

    int3 ModalSound::GetNormalizedID(float3 center)
    {
        auto y = center.x;
        auto x = -center.y;
        center.x = x;
        center.y = y;
        size_t voxelNum = voxelData.batchs - 1;
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
        int *voxelDataPointer = rawVoxelData.data<int>();
        size_t xSize = rawVoxelData.shape[0], ySize = rawVoxelData.shape[1],
               zSize = rawVoxelData.shape[2];

        // allocate memory.
        voxelData = CArr3D<int>(xSize, ySize, zSize, voxelDataPointer);
        vertData.resize(xSize + 1, ySize + 1, zSize + 1);
        vertData.reset();

        // check voxel in object.
        for (size_t i = 0; i < xSize; i++)
        {
            for (size_t j = 0; j < ySize; j++)
            {
                for (size_t k = 0; k < zSize; k++)
                {
                    if (voxelData(i, j, k) == 1)
                    {
                        for (auto &offset : MaterialConst::offsets)
                        {
                            vertData(i + offset[0], j + offset[1], k + offset[2]) = 1;
                        }
                    }
                }
            }
        }

        // put id in vert bucket.
        int cnt = 0;
        for (size_t i = 0; i < xSize + 1; i++)
        {
            for (size_t j = 0; j < ySize + 1; j++)
            {
                for (size_t k = 0; k < zSize + 1; k++)
                {
                    if (vertData(i, j, k) == 1)
                    {
                        vertData(i, j, k) = cnt;
                        cnt++;
                    }
                }
            }
        }
        return;
    }

    void ModalSound::SetMaterial(int chosenID, bool needShade)
    {
        LOG("SetMaterial: " << chosenID);
        for (auto &modalInfo : modalInfos)
            modalInfo.SetMaterial(chosenID);
        if(needShade)
            mesh_render->changeMaterial(chosenID);
        return;
    }

    void ModalSound::SetModal(const char *eigenPath, const char *ffatPath, const char *voxelPath)
    {
        click_current_frame = false;
        cnpy::npz_t eigenData = cnpy::npz_load(eigenPath);
        cnpy::NpyArray &rawEigenValues = eigenData["vals"];             // get S
        cnpy::NpyArray &rawEigenVecs = eigenData["vecs"];               // get U
        cnpy::NpyArray rawFFAT = cnpy::npz_load(ffatPath, "feats_out"); // get FFAT.
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
        cnpy::NpyArray preTime = cnpy::npz_load(ffatPath, "time");
        assert(preTime.word_size == sizeof(double));
        preprocessTime = preTime.data<double>()[0];
        return;
    }

    inline float Lerp(float x1, float x2, float coeff)
    {
        return x1 * coeff + x2 * (1 - coeff);
    }

    float ModalSound::GetFFATFactor(ModalInfo &modalInfo)
    {
        auto campos = mesh_render->camera.Position * Correction::camScale;
        const float camx = campos[0], camy = campos[1], camz = campos[2];

        const float r = glm::length(campos) + 1e-4f; // to prevent singular point.
        const size_t ffatRowNum = modalInfo.ffat.size();
        const size_t ffatColNum = modalInfo.ffat[0].size();
        const float rowSampleIntervalRep = ffatRowNum / (2 * PI);
        const float colSampleIntervalRep = ffatColNum / PI;

        float theta = std::acos(camz / r);
        float phi = camy <= 1e-5f && camx <= 1e-5f && camx >= -1e-5f && camy >= -1e-5f ? 0.0f : std::fmod(std::atan2(camy, camx) + 2 * PI, 2 * PI);

        float colInter = theta * colSampleIntervalRep, rowInter = phi * rowSampleIntervalRep;
        int col = static_cast<int>(colInter);
        float colFrac = colInter - static_cast<float>(col);
        if (col < 0 || col > ffatColNum)
        {
            col = 0;
            colFrac = 0;
        }
        int row = static_cast<int>(rowInter);
        float rowFrac = rowInter - static_cast<float>(row);
        if (row < 0 || row > ffatRowNum)
        {
            row = 0;
            rowFrac = 0;
        }
        // std::cout << row << " " << row + 1 << " " << col << " " << col + 1 << "\n";
        // bi-Lerp.
        int nextRow = (row + 1) % ffatRowNum, nextCol = (col + 1) % ffatColNum;
        float interResult = Lerp(Lerp(modalInfo.ffat[row][col], modalInfo.ffat[nextRow][col], rowFrac),
                                 Lerp(modalInfo.ffat[row][nextCol], modalInfo.ffat[nextRow][nextCol], rowFrac), colFrac);

        return interResult / r;
    }

    void ModalSound::PreprocessAllModals(const std::filesystem::path &meshRootPath, const std::filesystem::path &scaleFilePath)
    {
        int cnt = std::distance(std::filesystem::directory_iterator(meshRootPath), std::filesystem::directory_iterator());
        int preprocessedCnt = 0;
        std::cout << "Totally " << cnt << " files in /meshes.\n";

        std::fstream correctionFile(scaleFilePath, std::ios::in | std::ios::out | std::ios::app);
        std::string modelName;
        float modalScale;
        while (correctionFile >> modelName >> modalScale)
        {
            Correction::allSoundScales.emplace(modelName, modalScale);
        };
        correctionFile.clear();

        [[maybe_unused]] const auto AsciiWStrToStr = [](const std::wstring &wstr)
        { return std::string(wstr.begin(), wstr.end()); };
        for (const auto &entry : std::filesystem::directory_iterator(meshRootPath))
        {
#ifdef _WIN32
            auto tempName = entry.path().filename().replace_extension(L"");
            modelName = AsciiWStrToStr(tempName.c_str());
#else
            modelName = entry.path().filename().replace_extension("");
#endif
            if (Correction::allSoundScales.find(modelName) == Correction::allSoundScales.end())
            {
#ifdef _WIN32
                auto meshPath = AsciiWStrToStr(entry.path().c_str());
#else
                auto meshPath = entry.path().c_str();
#endif
                auto mesh = loadOBJ(meshPath);
                MeshRender render;
                render.load_mesh(mesh.vertices, mesh.triangles, mesh.vertex_texcoords, mesh.tex_triangles);
                ModalSound modal;
                modal.link_mesh_render(&render);

                float currMinScale = 1e20;
                for(int i = 0; i < 7; i++)
                {
                    auto eigenPath = std::string(ASSET_DIR) + std::string("/eigen/") + modelName + "_" + MaterialConst::names[i] + std::string(".npz");
                    auto ffatPath = std::string(ASSET_DIR) + std::string("/acousticMap/") + modelName + "_" + MaterialConst::names[i] + std::string(".npz");
                    auto voxelPath = std::string(ASSET_DIR) + std::string("/voxel/") + modelName + std::string(".npy");
                    modal.SetModal(eigenPath.c_str(), ffatPath.c_str(), voxelPath.c_str());
                    modal.SetMaterial(i, false);
                    modal.AdjustSoundScale();
                    if(Correction::soundScale < currMinScale)
                        currMinScale = Correction::soundScale;
                } 
                Correction::allSoundScales.emplace(modelName, currMinScale);
                correctionFile << modelName << " " << currMinScale << "\n";
            }
            ++preprocessedCnt;
            std::cerr << preprocessedCnt << " files have finished preproecessing.\r";
        }
        std::cout << "\n";
        return;
    };
}