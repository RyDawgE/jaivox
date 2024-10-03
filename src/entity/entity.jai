Entity :: struct @entity {
    id : u64;
    
    active              : bool    = false;
    subscribed_to_input : bool    = false;
    
    position            : Vector3 = .{0, 0, 0};
    rotation            : Vector3 = .{0, 0, 0};
    scale               : Vector3 = .{1, 1, 1};
    
    input_bindings      : *Table(u32, INPUT_BINDING_PROCEDURE_SIGNATURE);
}

EntityBlock :: struct {
    member_mask : u64 = 0;
    memory : *void;
}

EntityHandle :: struct {
    entity_blocks : [..] EntityBlock;
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

LARGEST_ENTITY_SIZE :: #run get_entity_slot_size();

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
    array_unordered_remove_by_value(input_subscription, entity);
    
    return true;
}

subscribe_entity_to_input :: (entity : *Entity, input_handle : *InputHandle) {
    entity.subscribed_to_input = true;
    entity.input_bindings = New(Table(u32, INPUT_BINDING_PROCEDURE_SIGNATURE));
    
    array_add(*input_handle.subscribed_entities, entity);
    
    return;
}



