#pragma once
#include <SDL3/SDL.h>

class App
{
    static App* singleton;

public:

    App() { singleton = this; }
    ~App() { singleton = nullptr; }

    static App* instance() {
        return singleton;
    }

    void onStartup();
    void onFrame();
    void onShutdown();
    void onEvent(SDL_Event e);
};

[[nodiscard]] inline App* app()
{
    return App::instance();
}
