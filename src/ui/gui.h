#pragma once

#include <stdio.h>
#include "window.h"
#include "array.h"


namespace SoundRender
{
    class GUI
    {
        CArr<Window *> sub_windows;

    public:
        void start(int height = 1600, int width = 900);
        void update()
        {
            for (int i = 0; i < sub_windows.size(); i++)
            {
                sub_windows[i]->called();
            }
        }
        void add_window(Window *window)
        {
            sub_windows.pushBack(window);
        }
    };

}