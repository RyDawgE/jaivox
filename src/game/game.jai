GameState :: struct {
    should_close : bool = false;   
    entity_manager : *EntityManager;
    render_handle : *RenderHandle;
}

start_game :: (game_state: *GameState) {
    debug_counter : int = 0;
    game_state.entity_manager = New(EntityManager);
    
    while !game_state.should_close {
        entity : *Entity = cast (*Entity) create_entity(game_state.entity_manager, Entity);
        
        debug_counter += 1;
        
        if (debug_counter % 16 == 0) {
            destroy_entity(game_state.entity_manager, entity);
        }
        
        if (debug_counter == 1024) {
            game_state.should_close = true;
        }
        
    }
}