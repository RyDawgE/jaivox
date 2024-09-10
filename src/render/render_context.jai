RenderHandle :: struct {
    window : *GLFWwindow;
}

WindowCreationInfo :: struct {
    width : s32 : 640;
    height : s32 : 480;
    title : string : "Jaivox";
}

create_window :: (game_state : *GameState) {
    game_state.render_handle = New(RenderHandle);

    if !glfwInit() then return;
    defer glfwTerminate();
    
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
    
    game_state.render_handle.window = glfwCreateWindow(WindowCreationInfo.width, WindowCreationInfo.height, WindowCreationInfo.title, null, null);
    
    if !game_state.render_handle.window then return;
    
    defer glfwDestroyWindow(game_state.render_handle.window);
    
    glfwMakeContextCurrent(game_state.render_handle.window);
    
    while !glfwWindowShouldClose(game_state.render_handle.window) {
        glfwSwapBuffers(game_state.render_handle.window);
        glfwPollEvents();
    }
    
    
}