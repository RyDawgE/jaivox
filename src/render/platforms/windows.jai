create_game_window :: () {
    window_width  : s32    : WindowCreationInfo.width;
    window_height : s32    : WindowCreationInfo.height;
    window_title  : string : WindowCreationInfo.title;


    game_state.render_handle.window = create_window(window_width, window_height,
                                                    window_title, wanted_msaa = 0);

    return;
}

create_render_context :: () {
    gl_create_context(game_state.render_handle.window, 3, 3,
                           compatibility=false, debug=true);
    gl_load(*gl);
    gl_enable_debug_output(break_on_error = true);

    DumpGLErrors("context");

    return;
}

render_loop :: () {
}

cleanup_window :: (window : *void) {
    return;
}

#scope_file
#import "GL";
#import "Window_Creation";