cmake_minimum_required(VERSION 3.22)
project(SoundRender LANGUAGES CXX CUDA)
set(CMAKE_BUILD_TYPE Debug)
set(CMAKE_CUDA_ARCHITECTURES 60 75 86)
set(CMAKE_CXX_STANDARD 17)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/core 
                    ${CMAKE_CURRENT_SOURCE_DIR}/src/sound 
                    ${CMAKE_CURRENT_SOURCE_DIR}/src/sound/audio 
                    ${CMAKE_CURRENT_SOURCE_DIR}/src/sound/modal 
                    ${CMAKE_CURRENT_SOURCE_DIR}/src/ui 
                    )
add_subdirectory(libs)
add_subdirectory(src)
add_executable(main main.cu)
target_link_libraries(main PUBLIC guilib audiolib modallib imgui)
target_compile_definitions(main PRIVATE ASSET_DIR="${CMAKE_SOURCE_DIR}/asset")



