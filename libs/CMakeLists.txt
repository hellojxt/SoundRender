find_package(OpenGL REQUIRED)
find_package(GLEW REQUIRED)
find_package(glfw3 REQUIRED)
include_directories(${GLEW_INCLUDE_DIRS})
include_directories(${OPENGL_INCLUDE_DIRS})

#=================== IMGUI ===================

set(IMGUI_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/imgui)

list(APPEND IMGUI_PUBLIC_HEADERS
		"${IMGUI_SRC_DIR}/imgui.h"
		"${CMAKE_CURRENT_SOURCE_DIR}/implot.h"
		"${CMAKE_CURRENT_SOURCE_DIR}/implot_internal.h"
		)

list(APPEND IMGUI_PRIVATE_HEADERS
		"${IMGUI_SRC_DIR}/imgui_internal.h"
		"${IMGUI_SRC_DIR}/imconfig.h"
		"${IMGUI_SRC_DIR}/stb_rect_pack.h"
		"${IMGUI_SRC_DIR}/stb_textedit.h"
		"${IMGUI_SRC_DIR}/stb_truetype.h"
		)

list(APPEND IMGUI_SOURCES
		"${CMAKE_CURRENT_SOURCE_DIR}/implot_items.cpp"
		"${CMAKE_CURRENT_SOURCE_DIR}/implot.cpp"
		"${IMGUI_SRC_DIR}/imgui.cpp"
		"${IMGUI_SRC_DIR}/imgui_draw.cpp"
		"${IMGUI_SRC_DIR}/imgui_demo.cpp"
		"${IMGUI_SRC_DIR}/imgui_widgets.cpp"
		"${IMGUI_SRC_DIR}/imgui_tables.cpp"
		"${IMGUI_SRC_DIR}/backends/imgui_impl_glfw.cpp"
		"${IMGUI_SRC_DIR}/backends/imgui_impl_opengl3.cpp"
		)

list(APPEND IMGUI_PUBLIC_INCLUDE_DIRS
		${IMGUI_SRC_DIR}
		)


set(NAME imgui)
add_library(${NAME} STATIC ${IMGUI_SOURCES})
target_link_libraries(${NAME} PUBLIC ${OPENGL_LIBRARIES} glfw ${GLEW_LIBRARIES})
target_include_directories(${NAME}
		PUBLIC ${IMGUI_PUBLIC_INCLUDE_DIRS}
                ${GLFW_DIR}/include
                ${GLEW_INCLUDE_DIRS}
				${CMAKE_CURRENT_SOURCE_DIR}
				${CMAKE_CURRENT_SOURCE_DIR}/glm
		PRIVATE ${IMGUI_PRIVATE_INCLUDE_DIRS}
		)


