main :: () {
    game_state.start_time = cast (float) to_float64_seconds (current_time_monotonic()); 

    game_state.entity_handle = New(EntityHandle);
    game_state.render_handle = New(RenderHandle);
    game_state.input_handle  = New(InputHandle);

    initialize_entity_handle();
    create_render_engine();
    
    camera : *DebugCamera = create_entity(DebugCamera);

    init_debug_camera(camera);
    
    game_state.render_handle.bound_camera = camera;
    
    // for x : 0..2 {
    //     for z : 0..2 {
    //         chunk1 : *VoxelChunk = create_entity(VoxelChunk);
    //         create_voxel_chunk(chunk1, .{xx x, 0, xx z});
    //         chunk1.position = .{xx (x * CHUNK_SIZE * VOXEL_SIZE), 0, xx (z * CHUNK_SIZE * VOXEL_SIZE)};
    //     }
    // }
            
    camera.position += .{1, -.2, 8};
    
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
