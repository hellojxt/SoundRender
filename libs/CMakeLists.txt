find_package(OpenGL REQUIRED)


if(WIN32)
	include_directories(glew/include/GL)
	include_directories(glfw/include/GLFW)
	include_directories(zlib/include)
	include_directories(portaudio/include)
else()
	#on LINUX
	find_package(glfw3 REQUIRED)
	add_library(glewlib STATIC glew/src/glew.c glew/src/glewinfo.c glew/src/visualinfo.c)
	target_link_libraries(glewlib PUBLIC ${OPENGL_LIBRARIES} glfw)
	
	find_package(ZLIB REQUIRED)
	find_package(portaudio REQUIRED)
	include_directories(${ZLIB_INCLUDE_DIRS})
	include_directories(glew/include/GL)
	include_directories(glew/include)
endif()

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


if(WIN32)

	target_link_libraries(${NAME} 
	PUBLIC 
	${OPENGL_LIBRARIES} 
	${CMAKE_CURRENT_SOURCE_DIR}/glfw/lib/glfw3.lib 
	${CMAKE_CURRENT_SOURCE_DIR}/glfw/lib/glfw3_mt.lib  
	${CMAKE_CURRENT_SOURCE_DIR}/glfw/lib/glfw3dll.lib

	${CMAKE_CURRENT_SOURCE_DIR}/glew/lib/glew32.lib  
	${CMAKE_CURRENT_SOURCE_DIR}/glew/lib/glew32s.lib

	#${CMAKE_CURRENT_SOURCE_DIR}/zlib/lib/libz.lib
	${CMAKE_CURRENT_SOURCE_DIR}/zlib/lib/libz-static.lib
	#${CMAKE_CURRENT_SOURCE_DIR}/zlib/lib/libz.dll
	${CMAKE_CURRENT_SOURCE_DIR}/zlib/lib/libz.exp

	#${CMAKE_CURRENT_SOURCE_DIR}/portaudio/lib/portaudio_x64.lib
	${CMAKE_CURRENT_SOURCE_DIR}/portaudio/lib/portaudio_static_x64.lib
	#${CMAKE_CURRENT_SOURCE_DIR}/portaudio/lib/portaudio_x64.dll
	)

	target_include_directories(${NAME}
	PUBLIC ${IMGUI_PUBLIC_INCLUDE_DIRS}
	${CMAKE_CURRENT_SOURCE_DIR}/glew/include/GL
	${CMAKE_CURRENT_SOURCE_DIR}/glfw/include/GLFW
	${CMAKE_CURRENT_SOURCE_DIR}/zlib/include
	${CMAKE_CURRENT_SOURCE_DIR}/portaudio/include
	${CMAKE_CURRENT_SOURCE_DIR}
	${CMAKE_CURRENT_SOURCE_DIR}/glm
	PRIVATE ${IMGUI_PRIVATE_INCLUDE_DIRS}
	)

else()
	#on LINUX
	target_link_libraries(${NAME} PUBLIC ${OPENGL_LIBRARIES} glfw glewlib ${ZLIB_LIBRARIES} portaudio_static)
	target_include_directories(${NAME}
			PUBLIC ${IMGUI_PUBLIC_INCLUDE_DIRS}
					${GLFW_DIR}/include
					${CMAKE_CURRENT_SOURCE_DIR}/glew/include
					${CMAKE_CURRENT_SOURCE_DIR}/glm
			PRIVATE ${IMGUI_PRIVATE_INCLUDE_DIRS}
			)

endif()




