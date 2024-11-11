main :: () {
    debug_counter : int = 0;
    game_state.entity_handle = New(EntityHandle);
    game_state.render_handle = New(RenderHandle);
    game_state.input_handle  = New(InputHandle);

    create_render_engine();
    
    entity : *Entity = create_entity(Entity);
    camera : *Entity = create_entity(Entity);
    
    subscribe_entity_to_input(entity, game_state.input_handle);
    create_input_binding(entity, 27, close_game_binding);
    create_input_binding(entity, 130, rotate_left);
    create_input_binding(entity, 131, rotate_right);
        
    subscribe_entity_to_input(camera, game_state.input_handle);
    create_input_binding(camera, .KEY_W, move_forward);
    create_input_binding(camera, .KEY_S, move_backward);
    create_input_binding(camera, .KEY_A, move_left);
    create_input_binding(camera, .KEY_D, move_right);
    create_input_binding(camera, .KEY_E, move_up);
    create_input_binding(camera, .KEY_Q, move_down);
    
    game_state.render_handle.bound_camera = camera;
    
    chunk : VoxelChunk = .{};
    
    populate_chunk(*chunk);
    
    model : Model = create_model(VERTS, INDICES);
    
    entity.model = *model;
    camera.position += .{2, 2, 2};
        
    // @MainLoop
    while !game_state.should_close {
        poll_events();
        simulate_game();
        draw_frame();
    }
    cleanup();
}

simulate_game :: () {
    for block : game_state.entity_handle.entity_blocks {
        mask : u64 = block.member_mask;
        for i : 0..64 { 
            forward_bit : u64 = mask >> i;
            if forward_bit & 1 == 1 {
                entity : *Entity = xx (block.memory + (LARGEST_ENTITY_SIZE * i));
                
                entity.position += entity.movement * .05;
            }    
        }
    }
}

cleanup :: () {
    cleanup_render_engine();
}

print_size_info :: () #compile_time {
    print("\nDebug size info: \n");
    print("Largest Entity: % bytes.\n", LARGEST_ENTITY_SIZE);
    print("Chunk Data: % bytes.\n", size_of(VoxelChunk));
    print("\n");
}

#run print_size_info();

#load "./game/game.jai";
#load "./entity/entity.jai";
#load "./voxel/voxel.jai";
#load "./render/render.jai";
#load "./input/input.jai";
#load "./file_utilities.jai";
#load "./memory_utilities.jai";
#load "./math_utilities.jai";

// platform dependent file inclusion
#if OS ==  {
    case .WINDOWS;

    case .MACOS; #assert false "MacOS is not supported at this time.";
    case .LINUX; #assert false "Linux is not supported at this time.";
}

#import "Basic";
#import "Math";
#import "Bit_Operations";
#import "Compiler";
#import "Hash_Table";
#import "String";
#import "System";