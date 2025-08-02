Battle :: struct {
    enemy_kinds : []EnemyKind = .[
        .ROARING_KNIGHT,
        //.ROARING_KNIGHT,

    ];
    
}

UserGameState :: struct {
    battle : *Battle;
    deck   : [..]Card;
    hand   : [..]*SelectableCard;
    hand_size : u16 = 11;
    enemies : [..]*EnemyBattle;
    players : [..]*PlayerBattle;
    target_index : int = 0;
}

GameState :: struct {
    should_close  : bool    = false;
    delta_time    : float   = 0;
    start_time    : float   = 0;
    frame         : u32     = 0;
    time          : float   = 0;

    scene          : *Scene;

    entity_handle  : *EntityHandle;
    render_handle  : *RenderHandle;
    input_handle   : *InputHandle;

    using user : UserGameState;
}

game_state : GameState = .{};

close_game_binding :: (entity: *Entity, event : *Event) {
    if event.key_pressed == 1 {
        game_state.should_close = true;
    }
}

update_game_state :: () {

}

load_scene :: (scene : *Scene) {
    if (game_state.scene) {
        cleanup_scene(game_state.scene);
    };

    if (!scene.entity_handle) {
        scene.entity_handle = New(EntityHandle);
        initialize_entity_handle(scene.entity_handle);
    }

    game_state.entity_handle = scene.entity_handle;

    game_state.scene = scene;
    set_background_texture(scene.background);
    flush_events();
    array_reset(*game_state.render_handle.subscribed_entities);
    array_reset(*game_state.input_handle.subscribed_entities);


    scene.entry_procedure(scene);
};

#load "./deck.jai";