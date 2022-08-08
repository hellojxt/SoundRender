#include "window.h"
#include "gui_kernel.h"
#include "stb_image.h"
#include <thrust/extrema.h>
#include <thrust/execution_policy.h>

namespace SoundRender
{
    void MeshRender::loadTexture(const char* path)
    {
        int width, height, channels;
        unsigned char* data = stbi_load(path, &width, &height, &channels, 0);
        if(data == nullptr)
        {
            std::cout << "Texture failed to load at path : " << path << std::endl;
            stbi_image_free(data);
            textureID = 0;
        }
        GLenum format;
        switch (channels)
        {
        case 1:
            format = GL_RED;
            break;
        case 3:
            format = GL_RGB;
            break;
        case 4:
            format = GL_RGBA; 
            break;
        }
        glBindTexture(GL_TEXTURE_2D, textureID);
        glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, data);
        // glGenerateMipmap(GL_TEXTURE_2D);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        stbi_image_free(data);
        glBindTexture(GL_TEXTURE_2D, 0);
        return;
    }

    void MeshRender::loadSkycube(const std::string& path)
    {
        glBindTexture(GL_TEXTURE_CUBE_MAP, skycubeID);
        auto loadOneFacet = [&path](unsigned int MACRO, const char* name){
            int width, height, channels;
            unsigned char* data = stbi_load((path + name).c_str(), &width, &height, &channels, 0);
            if(data == nullptr)
            {
                std::cout << "Texture failed to load at path : " << path << std::endl;
                stbi_image_free(data);
                return;
            }
            GLenum format;
            switch (channels)
            {
            case 1:
                format = GL_RED;
                break;
            case 3:
                format = GL_RGB;
                break;
            case 4:
                format = GL_RGBA; 
                break;
            }
            glTexImage2D(MACRO, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, data);
            stbi_image_free(data);
            return;
        };

        loadOneFacet(GL_TEXTURE_CUBE_MAP_POSITIVE_X, "cm_pos_x.png");
        loadOneFacet(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, "cm_neg_x.png");
        loadOneFacet(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, "cm_pos_z.png");
        loadOneFacet(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, "cm_neg_z.png");
        loadOneFacet(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, "cm_pos_y.png");
        loadOneFacet(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, "cm_neg_y.png");

        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
        return;
    }


    void MeshRender::Prepare(std::string mtlLibName)
    {
        mtlLib = mtlLibName;
        return;
    }

    void MeshRender::init()
    {
        glGenTextures(1, &textureID);
        glGenTextures(1, &skycubeID);
        material = loadMaterial(std::string(ASSET_DIR) + std::string("/materials/") + mtlLib, "Ceramic_Glazed");
        bool useTexture = material.texturePicName.length() != 0;
        if(useTexture)
        {
            std::string texturePath = std::string(ASSET_DIR) + std::string("/materials/") + material.texturePicName;
            loadTexture(texturePath.c_str());
        }
        glGenFramebuffers(1, &framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        // glEnable(GL_TEXTURE_2D);
        glGenTextures(1, &textureColorbuffer);
        glBindTexture(GL_TEXTURE_2D, textureColorbuffer);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 1000, 1000, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureColorbuffer, 0);
        glBindTexture(GL_TEXTURE_2D, 0);
        
        glGenRenderbuffers(1, &rbo);
        glBindRenderbuffer(GL_RENDERBUFFER, rbo);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, 1000, 1000);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rbo);
        glBindRenderbuffer(GL_RENDERBUFFER, 0);
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
            LOG_ERROR("Framebuffer not complete!")
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        shader.load(std::string(SHADER_DIR) + std::string("/mesh.vert"),
                    std::string(SHADER_DIR) + std::string("/mesh.frag"));
        shader.use();
        shader.setInt("Texture", 0);
        shader.setInt("skyCube", 1);
        shader.setVec3("ambientCoeff", material.ambientCoeff.x, material.ambientCoeff.y, material.ambientCoeff.z);
        shader.setVec3("diffuseCoeff", material.diffuseCoeff.x, material.diffuseCoeff.y, material.diffuseCoeff.z);
        shader.setVec3("specularCoeff", material.specularCoeff.x, material.specularCoeff.y, material.specularCoeff.z);
        shader.setFloat("specularExp", material.specularExp);
        shader.setFloat("alpha", material.alpha);
        shader.setInt("useTexture", (int)useTexture);
        shader.setInt("useSkyCube", 0);
    }

    void MeshRender::resize()
    {
        ImVec2 size = ImGui::GetWindowSize();
        if (size.x != wsize.x || size.y != wsize.y)
        {
            wsize = size;
            float tx = wsize.x * OVERSAMPLE, ty = wsize.y * OVERSAMPLE;
            glBindTexture(GL_TEXTURE_2D, textureColorbuffer);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, tx, ty, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL);
            glBindTexture(GL_TEXTURE_2D, 0);
            glBindRenderbuffer(GL_RENDERBUFFER, rbo);
            glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, tx, ty);
            glBindRenderbuffer(GL_RENDERBUFFER, 0);
        }
    }

    void MeshRender::updateMesh()
    {
        glGenVertexArrays(1, &meshVAO);
        glGenBuffers(1, &meshVBO);
        glBindVertexArray(meshVAO);
        glBindBuffer(GL_ARRAY_BUFFER, meshVBO);
        glBufferData(GL_ARRAY_BUFFER, sizeof(Triangle) * meshData.size(), meshData.data(), GL_STATIC_DRAW);
        // position attribute
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 9 * sizeof(float) + sizeof(int), (void *)0);
        glEnableVertexAttribArray(0);
        // normal attribute
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 9 * sizeof(float) + sizeof(int), (void *)(3 * sizeof(float)));
        glEnableVertexAttribArray(1);
        // index attribute
        glVertexAttribIPointer(2, 1, GL_INT, 9 * sizeof(float) + sizeof(int), (void *)(9 * sizeof(float)));
        glEnableVertexAttribArray(2);
        // texture attribute
        glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, 9 * sizeof(float) + sizeof(int), (void*)(6 * sizeof(float)));
        glEnableVertexAttribArray(3);
    }

    void MeshRender::event()
    {
        bool isHovered = ImGui::IsWindowHovered();
        bool isFocused = ImGui::IsWindowFocused();
        bool isMiddleDown = ImGui::IsMouseDown(ImGuiMouseButton_Middle);
        bool isRightClick = ImGui::GetIO().MouseClicked[ImGuiMouseButton_Right];
        if (!inDrag && isHovered && isMiddleDown)
        {
            inDrag = true;
            dragX = ImGui::GetMouseDragDelta(ImGuiMouseButton_Middle).x;
            dragY = ImGui::GetMouseDragDelta(ImGuiMouseButton_Middle).y;
        }
        if (inDrag && !isMiddleDown)
        {
            inDrag = false;
        }
        if (inDrag)
        {
            float dragX_new = ImGui::GetMouseDragDelta(ImGuiMouseButton_Middle).x;
            float dragY_new = ImGui::GetMouseDragDelta(ImGuiMouseButton_Middle).y;
            auto right = camera.Right();
            camera.rotate(dragY_new - dragY, right);
            auto up = camera.Up;
            auto worldUp = glm::vec3(0.0f, 1.0f, 0.0f);
            if (glm::dot(up, worldUp) < 0)
                worldUp = -worldUp;
            camera.rotate(dragX_new - dragX, worldUp);
            dragX = dragX_new;
            dragY = dragY_new;
        }
        if (isHovered)
        {
            float wheelx = ImGui::GetIO().MouseWheel;
            camera.ProcessMouseScroll(wheelx);
        }
        auto rect_min = ImGui::GetItemRectMin();
        auto mouse_pos = ImGui::GetMousePos();
        float relative_x = (mouse_pos.x - rect_min.x) / wsize.x * 2.0f - 1.0f;
        float relative_y = (mouse_pos.y - rect_min.y) / wsize.y * 2.0f - 1.0f;
        if (isHovered && isRightClick)
        {
            auto image_pos = glm::vec4(relative_x, -relative_y, 1.0f, 1.0f);
            auto world_pos = glm::inverse(camera_projection) * image_pos;
            // LOG("image_pos: " << image_pos.x << " " << image_pos.y << " " << image_pos.z << " " << image_pos.w << std::endl);
            // LOG("world_pos: " << world_pos.x << " " << world_pos.y << " " << world_pos.z);
            world_pos.w = 1.0f;
            world_pos = glm::inverse(camera_view) * world_pos;
            // LOG("ray_target: " << world_pos.x << " " << world_pos.y << " " << world_pos.z << " " << world_pos.w << std::endl);
            GArr<float> distance(triangles_g.size());
            float3 ray_origin = make_float3(camera.Position.x, camera.Position.y, camera.Position.z);
            float3 ray_target = make_float3(world_pos.x, world_pos.y, world_pos.z);
            float3 ray_direction = ray_target - ray_origin;
            cuExecuteBlock(triangles_g.size(), CUDA_BLOCK_SIZE, ray_mesh_distance_kernel, vertices_g, triangles_g, ray_origin, ray_direction, distance);
            auto result_ptr = thrust::min_element(thrust::device, distance.begin(), distance.end());
            GArr<float> result(result_ptr, 1);
            int min_idx = result_ptr - distance.begin();
            if (result.last_item() < FLT_MAX)
            {
                if (selectedTriangle >= 0)
                {
                    meshData[selectedTriangle].flag1 = 0;
                    meshData[selectedTriangle].flag2 = 0;
                    meshData[selectedTriangle].flag3 = 0;
                    selectedTriangle = -1;
                }
                selectedTriangle = min_idx;
                meshData[selectedTriangle].flag1 = 1;
                meshData[selectedTriangle].flag2 = 1;
                meshData[selectedTriangle].flag3 = 1;
                meshNeedsUpdate = true;
                soundNeedsUpdate = true;
            }
        }
    }

    void MeshRender::load_mesh(CArr<float3> vertices_, CArr<int3> triangles_, CArr<float3> texverts_, CArr<int3> textris_)
    {
        vertices = vertices_;
        triangles = triangles_;
        // get bounding box
        float3 min_pos = vertices[0];
        float3 max_pos = vertices[0];
        for (int i = 1; i < vertices.size(); i++)
        {
            min_pos.x = min(min_pos.x, vertices[i].x);
            min_pos.y = min(min_pos.y, vertices[i].y);
            min_pos.z = min(min_pos.z, vertices[i].z);
            max_pos.x = max(max_pos.x, vertices[i].x);
            max_pos.y = max(max_pos.y, vertices[i].y);
            max_pos.z = max(max_pos.z, vertices[i].z);
        }
        // normalize vertices and move to center
        float3 center = (min_pos + max_pos) / 2.0f;
        float3 scale_f3 = (max_pos - min_pos) / 2.0f;
        float scale  = max(max(scale_f3.x, scale_f3.y), scale_f3.z);
        for (int i = 0; i < vertices.size(); i++)
        {
            vertices[i] = (vertices[i] - center) / scale;
        }
        bbox_min = make_float3(-1.0f, -1.0f, -1.0f);
        bbox_max = make_float3(1.0f, 1.0f, 1.0f);
        vertices_g.assign(vertices);
        triangles_g.assign(triangles);
        texverts_g.assign(texverts_);
        textriangles_g.assign(textris_);
        meshData_g.resize(triangles_g.size());
        GArr<float3> vert_norm;
        vert_norm.resize(vertices_g.size());
        cuExecute(triangles_g.size(), mesh_preprocess, vertices_g, triangles_g, texverts_g, textriangles_g, meshData_g, vert_norm);
        cuExecute(triangles_g.size(), mesh_preprocess_normals, triangles_g, meshData_g, vert_norm);
        meshData.assign(meshData_g);
        meshNeedsUpdate = true;
    }

    void MeshRender::resetMesh()
    {

    }

    void MeshRender::update()
    {
        ImGui::BeginChild("Render");
        resize();
        event();
        if (meshNeedsUpdate)
        {
            updateMesh();
            meshNeedsUpdate = false;
        }
        float tx = wsize.x * OVERSAMPLE, ty = wsize.y * OVERSAMPLE;
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        glViewport(0, 0, tx, ty);
            glEnable(GL_DEPTH_TEST);
        glClearColor(0.3f, 0.3f, 0.3f, 0.3f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // shader.setVec3("objectColor", 0.5f, 0.5f, 0.31f);
        shader.setVec3("lightColor", 1.0f, 1.0f, 1.0f);
        shader.setVec3("selectedColor", 1.0f, 0.0f, 0.0f);

        for (int light_idx = 0; light_idx < pointLightPositions.size(); light_idx++)
        {
            shader.setVec3("lightPos[" + std::to_string(light_idx) + "]", pointLightPositions[light_idx]);
        }
        shader.setVec3("viewPos", camera.Position);
        // view/projection transformations
        float Zoom_delta = 0.0f;
        if (ty > tx)
        {
            auto fovy = glm::radians(camera.Zoom);
            auto aspect = ty / tx;
            Zoom_delta = atan(aspect * tan(fovy / 2)) * 2 - fovy;
        }
        camera_projection = glm::perspective(glm::radians(camera.Zoom) + Zoom_delta, tx / ty, 0.1f, 100.0f);
        camera_view = camera.GetViewMatrix();
        shader.setMat4("projection", camera_projection);
        shader.setMat4("view", camera_view);
        // world transformation
        glm::mat4 model = glm::mat4(1.0f);
        shader.setMat4("model", model);

        // render the mesh
        glBindVertexArray(meshVAO);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, textureID);
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_CUBE_MAP, skycubeID);
        glDrawArrays(GL_TRIANGLES, 0, 3 * meshData.size());
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glDisable(GL_DEPTH_TEST);
        ImGui::Image((ImTextureID)(uintptr_t)textureColorbuffer, wsize, ImVec2(0, 1), ImVec2(1, 0));
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        ImGui::EndChild();
    }

    void MeshRender::changeMaterial(int chosenID)
    {
        const char* materialNames[] = { "Ceramic_Glazed", "Glass_Simple", "Bright_tiles_square", "Plastic_Shader", "Rough_Iron_Steel", "Stainless_Steel", "wet_aluminium"};
        if(chosenID == 1) // glass
        {
            shader.setInt("useSkyCube", 1);
            std::string cubePath = std::string(ASSET_DIR) + std::string("/materials/");
            loadSkycube(cubePath);
            return;
        }
        material = loadMaterial(std::string(ASSET_DIR) + std::string("/materials/") + mtlLib, materialNames[chosenID]);

        bool useTexture = material.texturePicName.length() != 0;
        if(useTexture)
        {
            std::string texturePath = std::string(ASSET_DIR) + std::string("/materials/") + material.texturePicName;
            loadTexture(texturePath.c_str());
        }
        std::cout <<material.ambientCoeff.x << " " << material.ambientCoeff.y<< " " << material.ambientCoeff.z<<"\n";
        shader.setVec3("ambientCoeff", material.ambientCoeff.x, material.ambientCoeff.y, material.ambientCoeff.z);
        shader.setVec3("diffuseCoeff", material.diffuseCoeff.x, material.diffuseCoeff.y, material.diffuseCoeff.z);
        shader.setVec3("specularCoeff", material.specularCoeff.x, material.specularCoeff.y, material.specularCoeff.z);
        shader.setFloat("specularExp", material.specularExp);
        shader.setFloat("alpha", material.alpha);
        shader.setInt("useTexture", (int)useTexture);
        shader.setInt("useSkyCube", 0);
        std::cout << material.alpha << "\n";
        return;
    }

} // namespace  SoundRender
