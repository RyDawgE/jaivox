main :: () {
    game_state.start_time = cast (float) to_float64_seconds (current_time_monotonic()); 

    game_state.entity_handle = New(EntityHandle);
    game_state.render_handle = New(RenderHandle);
    game_state.input_handle  = New(InputHandle);

    initialize_entity_handle();
    create_render_engine();
    
    camera : *DebugCamera = create_entity(DebugCamera);
    world  : *VoxelWorld  = create_entity(VoxelWorld);

    init_debug_camera(camera);
    init_voxel_world(world);
        
    game_state.render_handle.bound_camera = camera;
    
    // num of chunks = rd ^ 2
    rd := 64;
    lod_intensity : float = 6;
    
    for x : 1..rd {
        for z : 1..rd {

            x_pos := x - (rd/2);
            z_pos := z - (rd/2);
        
            operation : VoxelChunkOperation;
            operation.coordinate = .{xx x_pos, 0, xx z_pos};
            
            queue_chunk_operation(world, operation);
        }
    }
    

            
    camera.position = .{-3, 7, 9};
    camera.rotation = .{42, 30, 0};
    
    frame_start : Apollo_Time;
    frame_end   : Apollo_Time;

    // @MainLoop
    while !game_state.should_close {
		frame_start = current_time_monotonic ();

        poll_events();
        simulate_game();
        draw_frame();
        
		frame_end = current_time_monotonic ();
		
		game_state.delta_time = cast (float) to_float64_seconds (frame_end - frame_start);
    }
    cleanup();
}

simulate_game :: () {
    for tick_proc : game_state.entity_handle.tickable_entities {
         // it_index of table is the hasmap key
        tick_proc(get_entity(it_index));
    }
    
    update_game_state();
}

cleanup :: () {
    cleanup_render_engine();
}

print_size_info :: () #compile_time {
    print("\nDebug size info: \n");
    print("Largest Entity: % bytes.\n", LARGEST_ENTITY_SIZE);
    print("Chunk Data: % bytes.\n", size_of(VoxelChunkData));
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
#load "./voxel/noise/perlin_noise.jai";

#load "./game/entities/debug_camera.jai";
#load "./game/entities/voxel_chunk.jai";
#load "./game/entities/voxel_world.jai";



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
