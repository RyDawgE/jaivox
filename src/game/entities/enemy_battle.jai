#scope_file
// these r gonna need to become members methinks
BATTLE_INTRO    : TextureData;
BATTLE_IDLE     : TextureData;
BATTLE_DEATH    : TextureData;
BATTLE_DAMAGE    : TextureData;


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

    health : int = 1;
    // Dead should actually be 2 things.
    // Dead and "Overkill". Death doesnt actually happen until the end
    // of scoring to prevent thread bullshit... and also for the actual
    // mechanic.
    dead   : bool = false;
    attack : int = 1;
    vibrator : float = 0; //no im not changing it
    
    attack_timer : float = 0;
    attack_interval : float = 5;
    can_attack      : bool = true;
    
    target_player_index : int = 0;

    base_pos : Vector2;
}

//These procedures should become generic, and the
//struct itself should maybe have procedure callbacks?
//Defo for tick and the animations at least.
init_enemy_battle :: (entity : *EnemyBattle) {
    // Create textures and buffer to GPU

    if entity.kind == {
        case .ROARING_KNIGHT; {
            entity.health = 100;
            entity.attack = 5;
            
            entity.attack_timer = 0;
            entity.attack_interval = 5;
            
            BATTLE_INTRO = create_texture_animated(TEX_KNIGHT_BATTLE_INTRO, 11);
            BATTLE_DEATH = create_texture_animated(TEX_KNIGHT_BATTLE_DEATH, 3);
            BATTLE_DAMAGE = create_texture_animated(TEX_KNIGHT_BATTLE_DAMAGE, 1);

            BATTLE_IDLE = create_texture(TEX_KNIGHT_IDLE);

            DEFAULT_SHADER = create_shader_program(
                get_shader_object("SPRITE_VERT"),
                get_shader_object("RAINBOW_SPRITE_FRAG"),
            );
            
            subscribe_entity_to_tick(entity, xx tick_enemy);
            subscribe_entity_to_tick(entity, xx tick_roaring_knight);
        }
    }

    // Subscriptions
    subscribe_entity_to_render(entity);
    
    // Transformation Defaults
    entity.scale = .{2, 2};
    entity.base_pos = entity.position;

    // Configure sprite defaults
    entity.sprite = New(Sprite);
    set_sprite_texture(entity.sprite, BATTLE_IDLE);
    entity.sprite.shader_program = DEFAULT_SHADER;
}

tick_enemy :: (enemy : *EnemyBattle) {
    enemy.attack_timer += game_state.delta_time;
    
    enemy.vibrator = lerp(enemy.vibrator, 0, game_state.delta_time*3);
    enemy.position.x = sin(enemy.vibrator)*5 + enemy.base_pos.x;
    
    if (enemy.attack_timer >= enemy.attack_interval) && enemy.can_attack && !enemy.dead {
        play_intro_anim(enemy);
        take_damage(game_state.players[enemy.target_player_index], enemy.attack);
        enemy.attack_timer = 0;
    }
}

play_intro_anim :: (enemy: *EnemyBattle) {
    sprite : *Sprite = New(Sprite);
    set_sprite_texture(sprite, BATTLE_INTRO);
    sprite.position += .{42,-22};
    sprite.shader_program = DEFAULT_SHADER;
    //@TODO: PlayRate member variable that is some multiplier that can be set? methinks?
    play_sprite_animation(*enemy.entity, sprite, 1, false, true);
}

play_death_anim :: (enemy: *EnemyBattle) {
    sprite : *Sprite = New(Sprite);
    set_sprite_texture(sprite, BATTLE_DEATH);
    sprite.position += .{42,-22};
    sprite.shader_program = DEFAULT_SHADER;
    play_sprite_animation(*enemy.entity, sprite, .25, true, false);
}

play_damage_anim :: (enemy: *EnemyBattle) {
    sprite : *Sprite = New(Sprite);
    set_sprite_texture(sprite, BATTLE_DAMAGE);
    sprite.position += .{42,-32};
    sprite.shader_program = DEFAULT_SHADER;
    play_sprite_animation(*enemy.entity, sprite, .5, false, true);
    // Damage number color should correspond to suit of card
}

take_damage :: (enemy : *EnemyBattle, damage : int) {
    enemy.vibrator = 30;
    enemy.health -= damage;
    if enemy.health <= 0 {
        kill(enemy);
    } else {
        play_damage_anim(enemy);
    }
    print("%\n", damage);

}

kill :: (enemy : *EnemyBattle) {
    enemy.dead = true;
    play_death_anim(enemy);
}

// Roaring Knight
tick_roaring_knight :: (enemy : *EnemyBattle) {
    using enemy;

    entity.velocity = .{0, sin(game_state.time*3)/1.5};
    entity.position += Vector2.{enemy.velocity.x, -enemy.velocity.y} * (100 * game_state.delta_time);
}



