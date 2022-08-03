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
	void Mesh::print()
	{
		std::cout << "Vertices:\n";
		for (auto v : vertices.m_data)
			std::cout << "(" << v.x << "," << v.y << "," << v.z << ")\n";
		std::cout << "Triangles:\n";
		for (auto f : triangles.m_data)
			std::cout << "[" << f.x << "," << f.y << "," << f.z << "]\n";
	}

	void Mesh::writeOBJ(std::string filename)
	{
	}

	Mesh loadOBJ(std::string file_name, bool log)
	{
		CArr<float3> vertices;
		CArr<int3> triangles;
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
			else if (prefix == "use_mtl")
			{
			}
			else if (prefix == "v") // Vertex position
			{
				float3 tmp;
				ss >> tmp.x >> tmp.y >> tmp.z;
				vertices.pushBack(tmp);
			}
			else if (prefix == "vt")
			{
				// ss >> temp_vec2.x >> temp_vec2.y;
				// vertex_texcoords.push_back(temp_vec2);
			}
			else if (prefix == "vn")
			{
				// ss >> temp_vec3.x >> temp_vec3.y >> temp_vec3.z;
				// vertex_normals.push_back(temp_vec3);
			}
			else if (prefix == "f")
			{
				int tmp;
				int counter = 0;
				std::vector<int> tmp_inds;
				while (ss >> tmp)
				{
					// Pushing indices into correct arrays
					if (counter == 0)
						tmp_inds.push_back(tmp - 1);
					// else if (counter == 1)
					// 	vertex_texcoord_indicies.push_back(temp_glint);
					// else if (counter == 2)
					// 	vertex_normal_indicies.push_back(temp_glint);

					// Handling characters
					if (ss.peek() == '/')
					{
						++counter;
						ss.ignore(1, '/');
					}
					else if (ss.peek() == ' ')
					{
						counter = 0;
						ss.ignore(1, ' ');
					}

					// Reset the counter
					if (counter > 2)
						counter = 0;
				}
				triangles.pushBack(make_int3(tmp_inds[0], tmp_inds[1], tmp_inds[2]));
			}
		}
		if (log)
		{
			// LOG
			std::cout << "Vertices number: " << vertices.size() << "\n";
			std::cout << "Triangles number: " << triangles.size() << "\n";
			// Loaded success
			std::cout << "OBJ file:" << file_name << " loaded!"
					  << "\n";
		}

		return Mesh(vertices, triangles);
	}

}
