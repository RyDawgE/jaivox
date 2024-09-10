create_window :: (render_handle : *RenderHandle) {
    if !glfwInit() then return;
    
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
    
    window_width : s32 : WindowCreationInfo.width;
    window_height : s32 : WindowCreationInfo.height;
    window_title : string : WindowCreationInfo.title;
    
    render_handle.window = glfwCreateWindow(window_width, window_height, window_title, null, null);
    glViewport(0, 0, cast(u32) window_width, cast(u32) window_height);
    
    if !render_handle.window then return;
    
    glfwMakeContextCurrent(render_handle.window);
    glfwSetFramebufferSizeCallback(render_handle.window, callback_on_window_resize);
}

callback_on_window_resize :: (window: *GLFWwindow, width : s32, height : s32) #c_call {
    glViewport(0, 0, cast(u32) width, cast(u32) height);
}

get_should_window_close :: (window : *void) -> bool {
    return glfwWindowShouldClose(cast(*GLFWwindow) window) == 1;
}

cleanup_window :: (window : *void) {
    glfwDestroyWindow(cast(*GLFWwindow) window);
    glfwTerminate();
}