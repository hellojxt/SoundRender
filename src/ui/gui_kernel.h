#pragma once
#include "macro.h"
#include "helper_math.h"
#include "window.h"
namespace SoundRender
{

    __global__ void mesh_preprocess(GArr<float3> vertices, GArr<int3> triangles, GArr<float3> texVerts, GArr<int3> texTris, GArr<Triangle> GLdata)
    {
        int tri_id = threadIdx.x + blockIdx.x * blockDim.x;
        if (tri_id >= triangles.size())
            return;
        int3 tri = triangles[tri_id];
        Triangle data;
        data.v1 = vertices[tri.x];
        data.v2 = vertices[tri.y];
        data.v3 = vertices[tri.z];
        // normalized normal
        auto normal = normalize(cross(data.v2 - data.v1, data.v3 - data.v1));
        data.n1 = normal;
        data.n2 = normal;
        data.n3 = normal;
        if(tri_id < texTris.size())
        {
            int3 texTri = texTris[tri_id];
            data.t1 = texVerts[texTri.x];
            data.t2 = texVerts[texTri.y];
            data.t3 = texVerts[texTri.z];
        }
        data.flag1 = 0;
        data.flag2 = 0;
        data.flag3 = 0;
        GLdata[tri_id] = data;
    }

    // ray triangle intersection distance, return max float if no intersection
    inline __device__ float ray_triangle_intersection_distance(const float3 &ray_origin, const float3 &ray_direction, const float3 &v1, const float3 &v2, const float3 &v3)
    {
        float3 e1 = v2 - v1;
        float3 e2 = v3 - v1;
        float3 p = cross(ray_direction, e2);
        float det = dot(e1, p);
        if (det > -0.00001 && det < 0.00001)
            return FLT_MAX;
        float inv_det = 1.0 / det;
        float3 tvec = ray_origin - v1;
        float u = dot(tvec, p) * inv_det;
        if (u < 0.0 || u > 1.0)
            return FLT_MAX;
        float3 q = cross(tvec, e1);
        float v = dot(ray_direction, q) * inv_det;
        if (v < 0.0 || u + v > 1.0)
            return FLT_MAX;
        float t = dot(e2, q) * inv_det;
        return abs(t);
    }


    __global__ void ray_mesh_distance_kernel(GArr<float3> vertices, GArr<int3> triangles, float3 ray_origin, float3 ray_direction, GArr<float> distance)
    {
        int tri_id = threadIdx.x + blockIdx.x * blockDim.x;
        if (tri_id >= triangles.size())
            return;
        int3 tri = triangles[tri_id];
        // printf("idx: %d  ray origin: (%.2f, %.2f, %.2f) ray direction: (%.2f, %.2f, %.2f)\n", tri_id, ray_origin.x, ray_origin.y, ray_origin.z, ray_direction.x, ray_direction.y, ray_direction.z);
        distance[tri_id] = ray_triangle_intersection_distance(ray_origin, ray_direction, vertices[tri.x], vertices[tri.y], vertices[tri.z]);
    }

    

}