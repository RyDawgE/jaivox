GameState :: struct {
    should_close : bool = false;   
    entity_manager : *EntityManager;
    render_handle : *RenderHandle;
}

start_game :: () {
    debug_counter : int = 0;
    game_state.entity_manager = New(EntityManager);
    game_state.render_handle = New(RenderHandle);
    
    initialize_render(game_state.render_handle);
    
    while !should_game_close() {
        render_loop();
    }
    
    cleanup();
}

should_game_close :: () -> bool {
    return game_state.should_close;
}

cleanup :: () {
    cleanup_window(game_state.render_handle.window);
}

