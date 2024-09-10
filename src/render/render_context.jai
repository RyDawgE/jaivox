RenderHandle :: struct {
    window : *void;
}

WindowCreationInfo :: struct {
    width : s32 : 640;
    height : s32 : 480;
    title : string : "Jaivox";
}

initialize_render :: (render_handle : *RenderHandle) {
  create_window(render_handle);
}