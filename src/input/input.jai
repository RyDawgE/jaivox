InputHandle :: struct {
    subscribed_entities : [..] *Entity;
}

poll_events :: () {
    update_window_events();

    for events_this_frame {
        if it.type == .QUIT {
            game_state.should_close = true;
        } else if it.type == .KEYBOARD {
            for entity : game_state.input_handle.subscribed_entities {
                callback, success := table_find(entity.input_bindings, cast (u32) it.key_code);

                if success {
                    callback(entity, *it);
                }
            }
        }
    }
}

INPUT_BINDING_PROCEDURE_SIGNATURE :: #type (entity: *Entity, event : *Event);
create_input_binding :: (entity : *Entity, key_code : u32, proc_callback : INPUT_BINDING_PROCEDURE_SIGNATURE) {
    table_add(entity.input_bindings, key_code, proc_callback);
    return;
}



#scope_file
#import "Input";
