#scope_file
CARD_ATLAS  : TextureData;
DEFAULT_SHADER : u32;
#scope_export

SelectableCard :: struct @entity {
    using #as entity : Entity;
    card : Card = .{.KING, .HEART};
    target_position : Vector2 = .{};
    selected : bool = false;
    hovered  : bool = false;
    ping     : float = 0;
}

init_selectable_card :: (entity : *SelectableCard, card : Card = .{}) {
    CARD_ATLAS = create_texture(TEX_CARDS_DECK);
    DEFAULT_SHADER = create_shader_program(
        get_shader_object("ATLAS_SPRITE_VERT"),
        get_shader_object("ATLAS_SPRITE_FRAG"),
    );

    // Subscriptions
    subscribe_entity_to_render(entity);
    subscribe_entity_to_tick(entity, xx tick_selectable_card);


    // Configure card details
    entity.card = card;

    // Configure sprite defaults
    entity.scale = .{2, 2};
    entity.sprite = New(Sprite);
    set_sprite_texture(entity.sprite, CARD_ATLAS);

    entity.sprite.texture_data.atlas_data.size_x = 13;
    entity.sprite.texture_data.atlas_data.size_y = 4;

    // Minus two to account for there not being 1, and starting 0 index
    entity.sprite.texture_data.atlas_data.x = cast (s32) bit_scan_reverse(entity.card.rank) -2;
    entity.sprite.texture_data.atlas_data.y = xx entity.card.suit;

    entity.sprite.shader_program = DEFAULT_SHADER;
}

tick_selectable_card :: (entity : *SelectableCard) {
    entity.position = lerp(entity.position, entity.target_position, game_state.delta_time*10);
    entity.velocity = .{0,
        sin(
            ( game_state.time + ( entity.target_position.x / 3 ) )
        ) / 8
    };

    entity.position += entity.velocity;

    entity.ping = lerp(entity.ping, 0, game_state.delta_time * 50);
    entity.rotation = sin(entity.ping)*20;
}

ping :: (entity : *SelectableCard, speed : float = 1) {
    entity.ping = 40;
}

set_selected :: (entity : *SelectableCard, selected : bool) {
    if selected != entity.selected {
        if selected {
            entity.target_position -= .{0, 25};
        } else {
            entity.target_position += .{0, 25};
        }
    }
    entity.selected = selected;
}

set_hovered :: (entity : *SelectableCard, hovered : bool) {
    if hovered != entity.hovered {
        if hovered {
            entity.target_position -= .{0, 15};
        } else {
            entity.target_position += .{0, 15};
        }
    }
    entity.hovered = hovered;
}

threaded_scoring :: (thread : *Thread) -> s64{
    player_id : u64 = thread.data.(*u64).*;
    player : *PlayerBattle = get_entity(player_id);
    sleep_milliseconds(1000);

    // Here is where straight / flush would go

    for card : player.playing_hand {
        ping(card);
        sleep_milliseconds(200);

        card.target_position.x = -100;
        play_throw_anim(player);
        sleep_milliseconds(500);
    }

    for card : player.playing_hand {
        destroy_entity(card);
    }

    player.is_scoring_hand = false;
    return 0;
}

//thread_init :: (thread: *Thread, proc: Thread_Proc, temporary_storage_size : s32 = 16384, starting_storage: *Temporary_Storage = null) -> bool {
score_hand :: (player : *PlayerBattle, hand : [..]*SelectableCard) {
    player.playing_hand = hand;

    t : *Thread = New(Thread);

    thread_init(t, threaded_scoring);
    t.data = *player.id;
    thread_start(t);
}