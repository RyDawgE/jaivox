GameState :: struct {
    should_close  : bool = false;
    entity_handle : *EntityHandle;
    render_handle : *RenderHandle;
    input_handle  : *InputHandle;
}

game_state : GameState = .{};

test_binding :: (entity: *Entity, event : *Event) {
    print("works!\n");
}