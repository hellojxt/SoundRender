#include "modal.h"
#include <queue>

namespace SoundRender
{
    // This is only used for non-filtered data.
    void ModalSound::FilterAndFillModalInfos(cnpy::NpyArray &rawEigenValues, cnpy::NpyArray &rawEigenVecs, cnpy::NpyArray &rawFFAT)
    {
        using namespace MaterialConst;
        using valInfo = std::tuple<float, size_t, float>;
        struct cmp
        {
            bool operator()(const valInfo a, const valInfo b) const
            {
                return std::get<0>(a) > std::get<0>(b);
            }
        };

        float *valueData = rawEigenValues.data<float>();
        size_t valueNum = rawEigenValues.num_vals;

        std::vector<valInfo> fitInfos;
        fitInfos.reserve(valueNum);

        int cnt = 0;
        for (size_t i = 0; i < valueNum; i++)
        {
            float lambda = valueData[i];
            float omega = std::sqrt(lambda);
            float ksi = (alpha + beta * lambda) / (2 * omega);
            float frequency = omega * std::sqrt(1 - ksi * ksi) / 2 * PI;
            if (frequency < 20 || frequency > 20000) // can not be heard.
                continue;
            ++cnt;
            fitInfos.emplace_back(frequency, i, lambda);
        }
        // TODO : or, we can use nth_element and traverse the vec.
        // cmp CmpStd;
        // auto ele = *std::nth_element(fitInfos.begin(), fitInfos.begin() + cnt, selectNum, CmpStd);
        // for(size_t i = 0; i < cnt; i++)
        // {
        //      if(cmpStd(fitsInfo[i], ele))
        //      {
        //          int index = std::get<1>(val);
        //          float lambda = std::get<2>(val);
        //          modalInfos.emplace_back(lambda, index, rawEigenVecs);
        //      }
        // }
        // modalInfos.emplace_back(std::get<2>(ele), std::get<1>(ele), rawEigenVecs);
        std::priority_queue<valInfo, std::vector<valInfo>, cmp> infoHeap(fitInfos.begin(), fitInfos.begin() + cnt);
        size_t selectNum = rawFFAT.shape[0];
        modalInfos.reserve(selectNum);
        for (int i = 0; i < selectNum; i++)
        {
            const valInfo &val = infoHeap.top();
            size_t index = std::get<1>(val);
            float lambda = std::get<2>(val);
            modalInfos.emplace_back(lambda, index, rawEigenVecs, rawFFAT);
            infoHeap.pop();
        }
        return;
    }

    // This one is used for filtered data.
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

    float Lerp(float x1, float x2, float coeff)
    {
        return x1 * coeff + x2 * (1 - coeff);
    }

}