main :: () {
    debug_counter : int = 0;
    game_state.entity_handle = New(EntityHandle);
    game_state.render_handle = New(RenderHandle);
    game_state.input_handle  = New(InputHandle);

    initialize_render(game_state.render_handle);
    
    entity := create_entity(Entity);
    subscribe_entity_to_input(entity, game_state.input_handle);
    create_input_binding(entity, 65, test_binding);

    // @MainLoop
    while !game_state.should_close {
        poll_events();
        draw_frame();
    }
    cleanup();
}

cleanup :: () {
    cleanup_vulkan_instance();
}

#load "./game/game.jai";
#load "./entity/entity.jai";
#load "./render/render_context.jai";
#load "./input/input.jai";

// platform dependent file inclusion
#if OS ==  {
    case .WINDOWS;
        #load "./render/platforms/windows.jai";

    case .MACOS; #assert false "MacOS is not supported at this time.";
    case .LINUX; #assert false "Linux is not supported at this time.";
}

#import "Basic";
#import "Math";
#import "Bit_Operations";
#import "Compiler";
#import "Hash_Table";
#import "String";
