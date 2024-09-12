RenderHandle :: struct {
    window : *void;
}

WindowCreationInfo :: struct {
    width : s32 : 640;
    height : s32 : 480;
    title : string : "Jaivox";
}

initialize_render :: (render_handle : *RenderHandle) {
    create_game_window(); // Create Game Window
    create_render_context(); // Create Render API Context, i.e. OpenGL / Vulkan
}