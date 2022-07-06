add_library(guilib STATIC gui.cu windows.cu)
target_compile_definitions(guilib PRIVATE SHADER_DIR="${CMAKE_SOURCE_DIR}/src/ui/shaders"
                                            CONFIG_FILE="${CMAKE_SOURCE_DIR}/src/ui/imgui.ini")
target_link_libraries(guilib imgui)

