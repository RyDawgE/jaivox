InputHandle :: struct {
    subscribed_entities : [..] *Entity;
}

// @TODO: Incorporate this and make more tables
InputBindType :: enum u8 {
    KEYDOWN :: 0;
    KEYUP   :: 1;
    HOLD    :: 2;
}

poll_events :: () {
    update_window_events();

    for events_this_frame {
        if it.type == .QUIT {
            game_state.should_close = true;
        } else if it.type == .KEYBOARD && it.repeat == false {
            if it.key_pressed == 1 {
                //print("%\n", cast (u32) it.key_code);
                for entity : game_state.input_handle.subscribed_entities {
                    callback, success := table_find(entity.input_bindings, cast (u32) it.key_code);
                    if success {
                        callback(entity, *it);
                    }
                }
            } else if it.key_pressed == 0 {
                // @TODO: handle keyup
            }
        }
    }
}

/*
    The input system works by binding a function callback to a given key PER ENTITY.
    You can create a procedure with the same signature as INPIUT_BINDING_PROCEDURE_SIGNATURE,
    and pass it's callback through to this function as well as the entity and the keycode.
    As long as the entity persists, pressing that key on the keyboard will call that function.
    Make sure to subscribe the entity to input first using subscribe_entity_to_input.
*/

// @TODO: Implement the InputBindType argument
INPUT_BINDING_PROCEDURE_SIGNATURE :: #type (entity: *Entity, event : *Event);
create_input_binding :: (entity : *Entity, key_code : u32, proc_callback : INPUT_BINDING_PROCEDURE_SIGNATURE, type : InputBindType = 0) {
    table_add(entity.input_bindings, key_code, proc_callback);
    return;
}



#scope_file
#import "Input";
