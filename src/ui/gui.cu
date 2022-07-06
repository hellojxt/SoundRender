#include "imgui.h"
#include "backends/imgui_impl_glfw.h"
#include "backends/imgui_impl_opengl3.h"
#include "gui.h"
#include "implot.h"

namespace SoundRender
{
    static void glfw_error_callback(int error, const char *description)
    {
        fprintf(stderr, "Glfw Error %d: %s\n", error, description);
    }
    void GUI::start(int height, int width)
    {
        glfwSetErrorCallback(glfw_error_callback);
        if (!glfwInit())
            return;
        printf("GLFW Initialized\n");
        const char *glsl_version = "#version 130";
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
        // glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);  // 3.2+ only
        // glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);            // 3.0+ only
        GLFWwindow *window = glfwCreateWindow(height, width, "Sound Renderer", NULL, NULL);
        if (window == NULL)
            return;

        glfwMakeContextCurrent(window);

        glfwSwapInterval(1); // Enable vsync
        if (glewInit() != GLEW_OK)
            exit(EXIT_FAILURE);

        IMGUI_CHECKVERSION();
        ImGui::CreateContext();
        ImPlot::CreateContext();
        ImGuiIO &io = ImGui::GetIO();
        (void)io;
        io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard; // Enable Keyboard Controls

        // Setup Dear ImGui style
        // ImGui::StyleColorsDark();
        ImGui::StyleColorsClassic();

        // Setup Platform/Renderer bindings
        ImGui_ImplGlfw_InitForOpenGL(window, true);
        ImGui_ImplOpenGL3_Init(glsl_version);
        io.Fonts->AddFontFromFileTTF("../asset/fonts/RadioCanada.ttf", 18.0f);
        ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

        io.IniFilename = CONFIG_FILE;

        for (int i = 0; i < sub_windows.size(); i++)
        {
            sub_windows[i]->init();
        }


        while (!glfwWindowShouldClose(window))
        {
            glfwPollEvents();

            // Start the Dear ImGui frame
            ImGui_ImplOpenGL3_NewFrame();
            ImGui_ImplGlfw_NewFrame();
            ImGui::NewFrame();
            ImGui::Text("FPS: %.4f", ImGui::GetIO().Framerate);
            update();

            // Rendering
            ImGui::Render();
            int display_w, display_h;
            glfwGetFramebufferSize(window, &display_w, &display_h);
            glViewport(0, 0, display_w, display_h);
            glClearColor(clear_color.x * clear_color.w, clear_color.y * clear_color.w, clear_color.z * clear_color.w, clear_color.w);
            glClear(GL_COLOR_BUFFER_BIT);
            ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

            glfwSwapBuffers(window);
        }

        // Cleanup
        ImGui_ImplOpenGL3_Shutdown();
        ImGui_ImplGlfw_Shutdown();
        ImPlot::DestroyContext();
        ImGui::DestroyContext();

        glfwDestroyWindow(window);
        glfwTerminate();
    }
}