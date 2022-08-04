#include "objIO.h"
#include <iostream>
#include <string>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>

namespace SoundRender
{

	Mesh::Mesh(CArr<float3> vertices_, CArr<int3> triangles_)
	{
		vertices = vertices_;
		triangles = triangles_;
	}

    Mesh::Mesh(CArr<float3> vertices_, CArr<int3> triangles_, CArr<float3> tex_, CArr<int3> tex_triangles_)
	{
		vertices = vertices_;
		triangles = triangles_;
		vertex_texcoords = tex_;
		tex_triangles = tex_triangles_;
	}

	void Mesh::print()
	{
		std::cout << "Vertices:\n";
		for (auto v : vertices.m_data)
			std::cout << "(" << v.x << "," << v.y << "," << v.z << ")\n";
		std::cout << "Triangles:\n";
		for (auto f : triangles.m_data)
			std::cout << "[" << f.x << "," << f.y << "," << f.z << "]\n";
		if(!vertex_texcoords.isEmpty())
		{
			std::cout << "Textures:\n";
			for (auto f : vertex_texcoords.m_data)
				std::cout << "[" << f.x << "," << f.y << "]\n";
		}
	}

	void Mesh::writeOBJ(std::string filename)
	{
	}

    void Mesh::loadMaterial(const std::filesystem::path& fileName, const std::string& materialName)
    {
        std::string prefix;
        std::ifstream fin(fileName.c_str());
        if(!fin.is_open())
            std::cout << "Fail to open mtl file : " << fileName.c_str() << "\n";
        std::string currMtlName;
        while(fin >> prefix)
        {
            if(prefix == "newmtl")
            {
                fin >> currMtlName;
                if(currMtlName == materialName)
                    break;
            }
        }
        while (true)
        {
            fin >> prefix;
			if(prefix == "newmtl" || !fin.good())
                break;
            else if(prefix == "Ns")
            {
                fin >> specularExp;
            }
            else if(prefix == "Ka")
            {
                fin >> ambientCoeff.x >> ambientCoeff.y >> ambientCoeff.z;
            }
            else if(prefix == "Kd")
            {
                fin >> diffuseCoeff.x >> diffuseCoeff.y >> diffuseCoeff.z;
            }
            else if(prefix == "Ks")
            {
                fin >> specularCoeff.x >> specularCoeff.y >> specularCoeff.z;
            }
            else if(prefix == "d")
            {
                fin >> alpha;
            }
			else if(prefix == "map_Kd")
			{
				fin >> texturePicName;
			}
        }
        return;
    }


	Mesh loadOBJ(std::string file_name, bool log)
	{
		std::filesystem::path assetPath{ASSET_DIR};
		#ifdef _WIN32
			assetPath /= L"materials";
		#else
			assetPath /= "materials";
		#endif

		CArr<float3> vertices;
		CArr<int3> triangles;
		CArr<int3> tex_triangles;
		CArr<float3> vertex_texcoords;
		std::stringstream ss;
		std::ifstream in_file(file_name);
		std::string line = "";
		std::string prefix = "";

		// std::cout << "Start reading\n";
		// File open error check
		if (!in_file.is_open())
		{
			std::cout << "Error opening file: " << file_name << "\n";
			exit(1);
		}

		std::string mtlLibName;
		std::string materialName;
		// Read one line at a time
		while (std::getline(in_file, line))
		{
			// Get the prefix of the line
			ss.clear();
			ss.str(line);
			ss >> prefix;

			if (prefix == "#")
			{
			}
			else if (prefix == "o")
			{
			}
			else if (prefix == "s")
			{
			}
			else if (prefix == "usemtl")
			{
				ss >> materialName;
			}
			else if(prefix == "mtllib")
			{
				ss >> mtlLibName;
			}
			else if (prefix == "v") // Vertex position
			{
				float3 tmp;
				ss >> tmp.x >> tmp.y >> tmp.z;
				vertices.pushBack(tmp);
				// fout << "v " << tmp.x << " " << tmp.y << " " << tmp.z << "\n";
			}
			else if (prefix == "vt")
			{
				float3 temp_vec2;
				ss >> temp_vec2.x >> temp_vec2.y;
				temp_vec2.z = 0.0f;
				vertex_texcoords.pushBack(temp_vec2);
				// fout << "vt " << temp_vec2.x << " " << temp_vec2.y << "\n";
			}
			else if (prefix == "vn")
			{
				// here we omit norm_inds.
				// ss >> temp_vec3.x >> temp_vec3.y >> temp_vec3.z;
				// vertex_normals.push_back(temp_vec3);
			}
			else if (prefix == "f")
			{
				int3 vert_inds;
				int3 norm_inds;
				int3 text_inds;
				char slash;

				ss >> vert_inds.x;
				if(ss.peek() == '/')
				{
					ss.get();
					if(ss.peek() == '/') // v1//n1 v2//n2 v3//n3
					{
						ss >> slash >> norm_inds.x >> vert_inds.y >> slash >> slash >> norm_inds.y
							>> vert_inds.z >> slash >> slash >> norm_inds.z;
						triangles.pushBack(vert_inds);
						// here we omit norm_inds.
					}
					else{
						ss >> text_inds.x;
						if(ss.peek() == '/') // v1/t1/n1 v2/t2/n2 v3/t3/n3
						{
							ss >> slash >> norm_inds.x >> vert_inds.y >> slash >> text_inds.y >> slash
								>> norm_inds.y >> vert_inds.z >> slash >> text_inds.z >> slash >> norm_inds.z;
							triangles.pushBack(vert_inds);
							tex_triangles.pushBack(text_inds);
							// fout << "f " << vert_inds.x << "/" << text_inds.x << " " << vert_inds.y << "/" << text_inds.y
							// 	<< " " << vert_inds.z << "/" << text_inds.z << "\n";
							// fout << "f " << vert_inds.x << " " << vert_inds.y << " " << vert_inds.z << "\n";
							// here we omit norm_inds.
						}
						else{ // v1/t1 v2/t2 v3/t3
							ss >> vert_inds.y >> slash >> text_inds.y >> vert_inds.z >> slash >> text_inds.z;
							triangles.pushBack(vert_inds);
							tex_triangles.pushBack(text_inds);
						}
					}
				}
				else{ // v1 v2 v3
					ss >> vert_inds.y >> vert_inds.z;
					triangles.pushBack(vert_inds);
				}
			}
		}
		std::for_each(triangles.begin(), triangles.end(), [](int3& a){ --a.x; --a.y; --a.z; });
		std::for_each(tex_triangles.begin(), tex_triangles.end(), [](int3& a){ --a.x; --a.y; --a.z; });
		if (log)
		{
			// LOG
			std::cout << "Vertices number: " << vertices.size() << "\n";
			std::cout << "Triangles number: " << triangles.size() << "\n";
			std::cout << "TextureVert number: " << vertex_texcoords.size() << "\n";
			std::cout << "TextureTri number : " << tex_triangles.size() << "\n";
			// Loaded success
			std::cout << "OBJ file:" << file_name << " loaded!"
					  << "\n";
		}
		Mesh mesh = vertex_texcoords.isEmpty()? Mesh(vertices, triangles) : Mesh(vertices, triangles, vertex_texcoords, tex_triangles);
		mesh.loadMaterial(assetPath / mtlLibName, materialName);
		return mesh;
	}

}
