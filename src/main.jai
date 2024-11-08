main :: () {
    debug_counter : int = 0;
    game_state.entity_handle = New(EntityHandle);
    game_state.render_handle = New(RenderHandle);
    game_state.input_handle  = New(InputHandle);

    create_render_engine();
    
    entity : *Entity = create_entity(Entity);
    
    subscribe_entity_to_input(entity, game_state.input_handle);
    create_input_binding(entity, 65, test_binding);
    create_input_binding(entity, 27, close_game_binding);
    create_input_binding(entity, 130, rotate_left);
    create_input_binding(entity, 131, rotate_right);
    
    chunk : VoxelChunk = .{};
    
    populate_chunk(*chunk);
    
    model : Model = create_model(VERTS, INDICES);
    
    entity.model = *model;
        
    // @MainLoop
    while !game_state.should_close {
        poll_events();
        draw_frame();
    }
    cleanup();
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