load_overworld_scene :: (scene : *Scene) {
        player := create_entity(PlayerOverworld);
        init_player_overworld(player);

        enemy : *EnemyOverworld = xx create_entity(EnemyOverworld);
        init_enemy_overworld(enemy);
        enemy.position = .{480, 240};
};

load_battle_scene :: (scene : *Scene) {
        game_state.render_handle.background_sprite.shader_program = create_shader_program(
            get_shader_object("SPRITE_VERT"),
            get_shader_object("BATTLEBG_FRAG"),
        );
        
        player := create_entity(PlayerOverworld);
        init_player_overworld(player);
};