#scope_file
CARD_ATLAS  : TextureData;
DEFAULT_SHADER : u32;
#scope_export

SelectableCard :: struct @entity {
    using #as entity : Entity;
    card : Card = .{.KING, .HEART};
}

init_selectable_card :: (entity : *SelectableCard) {
    CARD_ATLAS = create_texture(TEX_CARDS_DECK);
    DEFAULT_SHADER = create_shader_program(
        get_shader_object("ATLAS_SPRITE_VERT"),
        get_shader_object("ATLAS_SPRITE_FRAG"),
    );
    
    // Subscriptions
    subscribe_entity_to_render(entity);
        
    // Configure sprite defaults
    entity.scale = .{2, 2};
    entity.position = .{320, 240};
    entity.sprite = New(Sprite);
    set_sprite_texture(entity.sprite, CARD_ATLAS);
    
    entity.sprite.texture_data.atlas_data.size_x = 13;
    entity.sprite.texture_data.atlas_data.size_y = 4;
    
    // Minus two to account for there not being 1, and starting 0 index
    entity.sprite.texture_data.atlas_data.x = cast (s32) bit_scan_reverse(entity.card.rank) -2;
    entity.sprite.texture_data.atlas_data.y = xx entity.card.suit;
    
    entity.sprite.shader_program = DEFAULT_SHADER;
}