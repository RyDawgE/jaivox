load_overworld_scene :: (scene : *Scene) {
        player := create_entity(PlayerOverworld);
        init_player_overworld(player);
        player.position = .{120, 240};

        enemy := create_entity(EnemyOverworld);
        init_enemy_overworld(enemy);
        enemy.position = .{480, 240};
};

load_battle_scene :: (scene : *Scene) {
        game_state.render_handle.background_sprite.shader_program = create_shader_program(
            get_shader_object("SPRITE_VERT"),
            get_shader_object("BATTLEBG_FRAG"),
        );

        player := create_entity(PlayerBattle);
        init_player_battle(player);
        player.position = .{120, 240};
        play_anim(player);

        game_state.battle = New(Battle);

        for kind : game_state.battle.enemy_kinds {
            enemy : EnemyBattle = .{
                kind = kind,
            };
            y_pos : float = ( (480/(it_index+2)) ).(float);
            enemy.position = .{480,y_pos};
            ent := add_entity(*enemy, EnemyBattle);

            init_enemy_battle(ent);
            play_anim(ent);
        }
};

#scope_file
#load "../game/entities/player_overworld.jai";
#load "../game/entities/player_battle.jai";
#load "../game/entities/enemy_overworld.jai";
#load "../game/entities/enemy_battle.jai";