GameState :: struct {
    should_close : bool = false;   
    entity_manager : *EntityManager;
    render_handle : *RenderHandle;
}

start_game :: (game_state: *GameState) {
    debug_counter : int = 0;
    game_state.entity_manager = New(EntityManager);
    game_state.render_handle = New(RenderHandle);
    
    initialize_render(game_state.render_handle);
    
    while !should_game_close(game_state) {
        
        glClear(GL_COLOR_BUFFER_BIT);
        
        glfwSwapBuffers(game_state.render_handle.window);
        
        glfwPollEvents();
    }
    
    cleanup(game_state);
}

should_game_close :: (game_state : *GameState) -> bool {
    return get_should_window_close(game_state.render_handle.window) | game_state.should_close;
}

cleanup :: (game_state : *GameState) {
    cleanup_window(game_state.render_handle.window);
}

