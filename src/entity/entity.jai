LARGEST_ENTITY_SIZE :: #run get_entity_slot_size();

ENTITY_TICK_PROCEDURE_SIGNATURE :: #type (entity: *Entity);

Entity :: struct @entity {
    id : u64;
    
    active              : bool    = false;
    
    position            : Vector3 = .{0, 0, 0};
    rotation            : Vector3 = .{0, 0, 0};
    scale               : Vector3 = .{1, 1, 1};
    
    velocity            : Vector3 = .{0, 0, 0};
    
    model               : *Model;
    collider            : *EntityCollider;
    
    input_bindings      : *Table(KeyboardKey, INPUT_BINDING_PROCEDURE_SIGNATURE);
}

EntityBlock :: struct {
    member_mask : u64 = 0;
    memory : *void;
}

EntityHandle :: struct {
    entity_blocks : [..] EntityBlock;
    tickable_entities : *Table(u64, ENTITY_TICK_PROCEDURE_SIGNATURE);
}

initialize_entity_handle :: () {
    using game_state.entity_handle;
    
    tickable_entities  = New(Table(u64, ENTITY_TICK_PROCEDURE_SIGNATURE));
}

get_entity_slot_size :: () -> s64 #compile_time {
    largest : s64 = 0;
    for type: get_type_table() {
        if type == null then continue;
        if type.type != .STRUCT then continue;
        structure := cast(*Type_Info_Struct)type;
        if array_find(structure.notes, "entity") {
          largest = max(largest, type.runtime_size);
        }
    }
    print("\nLargest Entity: % bytes.\n\n", largest);
    return largest;
}


get_entity_mem_info :: (id : u64) -> u32, u32 { 
    //block, slot
    return (cast,no_check(u32) id >> 32) - 1, (cast,no_check(u32) id) - 1;
}

create_entity :: ($T : Type) -> *void {    

    // find first block with available slot
    available_block : *EntityBlock;
    available_block_index := 0;
    
    for block : game_state.entity_handle.entity_blocks {
        if !(block.member_mask == ~0) { // ~ flips all bits. so ~0b00000000 -> 0b11111111
            //if block not full
            available_block = *block;
            available_block_index = it_index;
        }
    }
    
    //if theres no available block create a new one
    if (available_block == null) {
        available_block = array_add(*game_state.entity_handle.entity_blocks);
        block_size := LARGEST_ENTITY_SIZE * 64;
        available_block.memory = alloc(block_size);
        available_block_index = game_state.entity_handle.entity_blocks.count - 1;
        //print("New entity block created with size of % bytes\n", block_size);
    }
    
    available_slot : s32 = bit_scan_forward(~available_block.member_mask) - 1;  
    bit_slot : u64 = (cast(u64) 1) << available_slot;
    available_block.member_mask |= bit_slot;
    
    //Create entity data, write it to block, pop original entity off stack.
    entity : *T = cast(*T)(available_block.memory + (available_slot * LARGEST_ENTITY_SIZE));
    entity.* = .{}; // default initialize as type T
    
    id : u64 = 0;
    id |= ((cast(u64) available_block_index + 1) << 32) | (cast(u64) available_slot + 1);
        
    entity.id = id;
    entity.active = true;
        
    return entity;
}

// destroy example: 
// in:
// 00110100 - member_mask
// 11111011 - ~(1 << slot)

// out: 
// 00110000
destroy_entity :: (entity : *Entity) -> bool {
    if (entity.id == 0 || entity.active == false) {
        return false; //Already inactive
    }
    
    entity.active = false;
    block, slot := get_entity_mem_info(entity.id);
    
    game_state.entity_handle.entity_blocks[block].member_mask &= ~((cast(u64) 1) << slot);
    
    input_subscription := *game_state.input_handle.subscribed_entities;
    if array_find(<<input_subscription, entity.id) {
        array_unordered_remove_by_value(input_subscription, entity.id);
        deinit(entity.input_bindings);
        free(entity.input_bindings);
    }    
    
    render_subscription := *game_state.render_handle.subscribed_entities;
    if array_find(<<render_subscription, entity.id) {
        array_unordered_remove_by_value(input_subscription, entity.id);
    }    
    
    if entity.model {
        free(entity.model);
    }
    
    return true;
}

get_entity :: (id : u64) -> *void {
    using game_state.entity_handle;

    ones : u64 = ~0;

    block_index : u64 = (id >> 32) - 1; // only back half
    slot_mask   : u64 = (ones >> 32);
    slot_index  : u64 = slot_mask & id; // only front half
    
    // print("block: %\n", formatInt(block_index, 2, 64));
    // print("mask: %\n", formatInt(slot_mask, 2, 64));
    // print("slot:  %\n", formatInt(slot_index, 2, 64));

    
    memory : *void = entity_blocks[block_index].memory;
    memory += (slot_index - 1) * LARGEST_ENTITY_SIZE;
    
    return memory;
}

subscribe_entity_to_input :: (entity : *Entity) {
    using game_state.input_handle;
    
    entity.input_bindings = New(Table(KeyboardKey, INPUT_BINDING_PROCEDURE_SIGNATURE));
    array_add(*subscribed_entities, entity.id);
    
    return;
}

// TODO: THIS SUCKS FOR A REAL REASON
// Every time this happens for entities of the same type, the exact
// same functions get added to the table multiple times under different keys for
// same entity types.

// To remedy, make the key based on Type and not entity ID, and add it to the table at compile time.
// Then, make should_tick be a boolean that checks if it should even enter the table to begin with.
subscribe_entity_to_tick :: (entity : *Entity, proc_callback : ENTITY_TICK_PROCEDURE_SIGNATURE = tick_entity) {
    using game_state.entity_handle;
    
    table_add(tickable_entities, entity.id, proc_callback);
    
    return;
}

subscribe_entity_to_render :: (entity : *Entity) {
    using game_state.render_handle;
    
    array_add(*subscribed_entities, entity.id);
    
    return;
}


tick_entity :: (entity : *Entity) {
    entity.position += entity.velocity * 0.03;
}


