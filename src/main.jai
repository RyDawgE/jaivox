EngineType :: enum u8 {
    ENGINE_3D   :: 0;
    ENGINE_2D   :: 1;
    //ENGINE_VR   :: 2; Make this a seperate flag later
}

EngineRenderer :: enum u8 {
    ENGINE_VK   :: 0;
    ENGINE_OGL  :: 1;
}

//TODO: Overall engine todo:
//Collisions
//Timer, proc runs after x amt of time. should run immediately, should loop, etc
//Sound
//Animation on finished lambda maybe?
//GUI
//Invest in better shader system. Not my proudest nut.


main :: () {
    game_state.start_time = cast (float) to_float64_seconds (current_time_monotonic());

    game_state.entity_handle  = New(EntityHandle);
    game_state.render_handle  = New(RenderHandle);
    game_state.input_handle   = New(InputHandle);

    initialize_entity_handle();
    create_render_engine();

    frame_start : Apollo_Time;
    frame_end   : Apollo_Time;

    //Main stuff goes here
    
    bg := create_texture(TEX_BG_HOMETOWN);
    set_background_texture(bg);
    
    player := create_entity(PlayerOverworld);
    init_player_overworld(player);

    enemy : *EnemyOverworld = xx create_entity(EnemyOverworld);
    init_enemy_overworld(enemy);
    enemy.position = .{480, 240};

    // @MainLoop
    while !game_state.should_close {
		frame_start = current_time_monotonic ();

        poll_events();
        simulate_game();
        draw_frame();

		frame_end = current_time_monotonic ();

		game_state.delta_time = cast (float) to_float64_seconds (frame_end - frame_start);

        game_state.time     += game_state.delta_time;
        game_state.frame    += 1;
		//Print FPS
		//print("%\n", frame_end);
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
    print("\n");
}

#run print_size_info();

#load "./game/game.jai";
#load "./entity/entity.jai";
#load "./render/render.jai";
#load "./input/input.jai";
#load "./file_utilities.jai";
#load "./memory_utilities.jai";
#load "./math_utilities.jai";
#load "./voxel/noise/perlin_noise.jai";

#load "./game/entities/player_overworld.jai";
#load "./game/entities/enemy_overworld.jai";




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
#import "File";
