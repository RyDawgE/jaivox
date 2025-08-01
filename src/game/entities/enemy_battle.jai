#scope_file
BATTLE_INTRO    : TextureData;
BATTLE_IDLE     : TextureData;

DEFAULT_SHADER   : u32;

BATTLE_ENEMY_PROCEDURE_SIGNATURE :: #type (entity : *EnemyBattle);

#scope_export

EnemyKind :: enum {
    DEFAULT;
    ROARING_KNIGHT;
}

EnemyBattle :: struct @entity {
    using #as entity : Entity;

    kind : EnemyKind = .DEFAULT;
    battle_intro_anim : TextureData;
}

//These procedures should become generic, and the
//struct itself should maybe have procedure callbacks?
//Defo for tick and the animations at least.
init_enemy_battle :: (entity : *EnemyBattle) {
    // Create textures and buffer to GPU

    if entity.kind == {
        case .ROARING_KNIGHT; {
            BATTLE_INTRO = create_texture_animated(TEX_KNIGHT_BATTLE_INTRO, 11);
            BATTLE_IDLE = create_texture(TEX_KNIGHT_IDLE);

            DEFAULT_SHADER = create_shader_program(
                get_shader_object("SPRITE_VERT"),
                get_shader_object("RAINBOW_SPRITE_FRAG"),
            );

            subscribe_entity_to_tick(entity, xx tick_roaring_knight);
        }
    }

    // Subscriptions
    subscribe_entity_to_render(entity);

    // Configure sprite defaults
    entity.scale = .{2, 2};
    entity.sprite = New(Sprite);
    set_sprite_texture(entity.sprite, BATTLE_IDLE);
    entity.sprite.shader_program = DEFAULT_SHADER;
}


play_intro_anim :: (enemy: *EnemyBattle) {
    sprite : *Sprite = New(Sprite);
    set_sprite_texture(sprite, BATTLE_INTRO);
    sprite.position += .{42,-22};
    sprite.shader_program = DEFAULT_SHADER;
    //@TODO: PlayRate member variable that is some multiplier that can be set? methinks?
    play_sprite_animation(*enemy.entity, sprite, 1, false, true);
}


// Roaring Knight
tick_roaring_knight :: (enemy : *EnemyBattle) {
    using enemy;

    entity.velocity = .{0, sin(game_state.time*3)/1.5};
    entity.position += Vector2.{enemy.velocity.x, -enemy.velocity.y} * (100 * game_state.delta_time);
}

