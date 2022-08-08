cmake_minimum_required(VERSION 3.22)
project(SoundRender LANGUAGES C CXX CUDA)
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CUDA_ARCHITECTURES 60 75 86)
set(CMAKE_CXX_STANDARD 17)
add_definitions(-DASSET_DIR="../asset")
# add_compile_options($<$<COMPILE_LANGUAGE:CUDA>:-G>)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/core 
                    ${CMAKE_CURRENT_SOURCE_DIR}/src/sound 
                    ${CMAKE_CURRENT_SOURCE_DIR}/src/sound/audio 
                    ${CMAKE_CURRENT_SOURCE_DIR}/src/sound/modal
                    ${CMAKE_CURRENT_SOURCE_DIR}/src/sound/cnpy
                    ${CMAKE_CURRENT_SOURCE_DIR}/src/ui 
	                ${CMAKE_CURRENT_SOURCE_DIR}/libs/zlib/include
                    )
add_subdirectory(libs)
add_subdirectory(src)
add_executable(demo main.cu)
target_link_libraries(demo PUBLIC guilib audiolib modallib imgui cnpylib corelib stdc++fs)


