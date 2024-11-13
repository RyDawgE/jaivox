main :: () {
    game_state.entity_handle = New(EntityHandle);
    game_state.render_handle = New(RenderHandle);
    game_state.input_handle  = New(InputHandle);

    initialize_entity_handle();
    create_render_engine();
    
    entity : *Entity = create_entity(Entity);
    camera : *DebugCamera = create_entity(DebugCamera);
    
    subscribe_entity_to_input(entity);
    create_input_binding(entity, 27, close_game_binding);
    create_input_binding(entity, 130, rotate_left);
    create_input_binding(entity, 131, rotate_right);
        
    init_debug_camera(camera);
    
    game_state.render_handle.bound_camera = camera;
    
    chunk : VoxelChunk = .{};
    
    populate_chunk(*chunk);
    
    model : Model = create_model(VERTS, INDICES);
    
    entity.model = *model;
    camera.position += .{0, -1, 4};
        
    // @MainLoop
    while !game_state.should_close {
		frame_start := current_time_monotonic ();

        poll_events();
        simulate_game();
        draw_frame();
        
		frame_end := current_time_monotonic ();
		game_state.delta_time = cast (float) to_float64_seconds (frame_end - frame_start);
    }
    cleanup();
}

simulate_game :: () {
    for tick_proc : game_state.entity_handle.tickable_entities {
         // it_index of table is key
        tick_proc(get_entity(it_index));
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

#load "./game/entities/debug_camera.jai";

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
