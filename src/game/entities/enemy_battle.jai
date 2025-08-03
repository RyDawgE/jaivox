#scope_file
// these r gonna need to become members methinks
BATTLE_INTRO        : TextureData;
BATTLE_IDLE         : TextureData;
BATTLE_OVERKILL     : TextureData;
BATTLE_DAMAGE       : TextureData;
BATTLE_HEAVY_DAMAGE : TextureData;
BATTLE_DEATH        : TextureData;



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
    overkill   : bool = false;
    dead   : bool = false;

    attack : int = 1;
    vibrator : float = 0; //no im not changing it
    
    attack_timer : float = 0;
    attack_interval : float = 5;
    can_attack      : bool = true;
    
    death_time : Apollo_Time;
    
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
            BATTLE_OVERKILL = create_texture_animated(TEX_KNIGHT_BATTLE_OVERKILL, 3);
            BATTLE_DAMAGE = create_texture_animated(TEX_KNIGHT_BATTLE_DAMAGE, 1);
            BATTLE_DEATH = create_texture_animated(TEX_KNIGHT_BATTLE_DEATH, 2);
            BATTLE_HEAVY_DAMAGE = create_texture_animated(TEX_KNIGHT_BATTLE_HEAVY_DAMAGE, 1);


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
    
    if (enemy.attack_timer >= enemy.attack_interval) && enemy.can_attack && !enemy.overkill && !enemy.dead {
        play_intro_anim(enemy);
        take_damage(game_state.players[enemy.target_player_index], enemy.attack);
        enemy.attack_timer = 0;
    }
    
    enemy.sprite.animation_frame = cast(s32)( (game_state.time*(6)) );
    
    //print("%\n", to_float64_seconds(current_time_monotonic() - enemy.death_time));
    
    if enemy.dead && (to_float64_seconds(current_time_monotonic() - enemy.death_time) >= 5) {
        destroy_entity(enemy);
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

play_overkill_anim :: (enemy: *EnemyBattle) {
    set_sprite_texture(enemy.sprite, BATTLE_OVERKILL);
}

play_death_anim :: (enemy: *EnemyBattle) {
    set_sprite_texture(enemy.sprite, BATTLE_DEATH);
}

play_damage_anim :: (enemy: *EnemyBattle) {
    sprite : *Sprite = New(Sprite);
    set_sprite_texture(sprite, BATTLE_DAMAGE);
    sprite.position += .{42,-32};
    sprite.shader_program = DEFAULT_SHADER;
    play_sprite_animation(*enemy.entity, sprite, .5, false, true);
    // Damage number color should correspond to suit of card
}

play_heavy_damage_anim :: (enemy: *EnemyBattle) {
    sprite : *Sprite = New(Sprite);
    set_sprite_texture(sprite, BATTLE_HEAVY_DAMAGE);
    //sprite.position += .{42,-32};
    sprite.shader_program = DEFAULT_SHADER;
    play_sprite_animation(*enemy.entity, sprite, .5, false, true);
    // Damage number color should correspond to suit of card
}

take_damage :: (enemy : *EnemyBattle, damage : int) {
    print("%\n", damage);
    enemy.vibrator = (ifx damage < 30 then 30 else 50).(float);
    enemy.health -= damage;
    if enemy.dead || enemy.overkill then return;
    
    if enemy.health <= 0 {
        play_heavy_damage_anim(enemy);
        enter_overkill(enemy);
    } else {
        play_damage_anim(enemy);
    }
}

enter_overkill :: (enemy : *EnemyBattle) {
    enemy.overkill = true;
    play_overkill_anim(enemy);
}

kill :: (enemy : *EnemyBattle) {
    enemy.dead = true;
    enemy.death_time = current_time_monotonic();
    play_death_anim(enemy);
}

// Roaring Knight
tick_roaring_knight :: (enemy : *EnemyBattle) {
    using enemy;

    entity.velocity = .{0, sin(game_state.time*3)/1.5};
    entity.position += Vector2.{enemy.velocity.x, -enemy.velocity.y} * (100 * game_state.delta_time);
}



