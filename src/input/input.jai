InputHandle :: struct {
    subscribed_entities : [..] u64;
    mouse_position : Vector2;
    mouse_delta : Vector2;
}

// @TODO: Incorporate this and make more tables
InputBindType :: enum u8 {
    KEYDOWN :: 0;
    KEYUP   :: 1;
    HOLD    :: 2;
}

poll_events :: () {
    update_window_events();
    
    game_state.input_handle.mouse_delta = .{xx mouse_delta_x, xx mouse_delta_y};

    for events_this_frame {
            
        if it.type == .QUIT {
            game_state.should_close = true;
        } else if it.type == .KEYBOARD && it.repeat == false {
            //print("%\n", cast (KeyboardKey) it.key_code);
            for id : game_state.input_handle.subscribed_entities {
                entity : *Entity = cast (*Entity) get_entity(id);
                callback, success := table_find(entity.input_bindings, cast (KeyboardKey) it.key_code);
                if success {
                    callback(entity, *it);
                }
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

create_input_binding :: (entity : *Entity, key_code : KeyboardKey, proc_callback : INPUT_BINDING_PROCEDURE_SIGNATURE) {

    table_add(entity.input_bindings, key_code, proc_callback);
    return;
}

KeyboardKey :: enum u32 {
    KEY_NULL            :: 0;
    // Alphanumeric keys
    KEY_APOSTROPHE      :: 39;
    KEY_COMMA           :: 44;
    KEY_MINUS           :: 45;
    KEY_PERIOD          :: 46;
    KEY_SLASH           :: 47;
    KEY_ZERO            :: 48;
    KEY_ONE             :: 49;
    KEY_TWO             :: 50;
    KEY_THREE           :: 51;
    KEY_FOUR            :: 52;
    KEY_FIVE            :: 53;
    KEY_SIX             :: 54;
    KEY_SEVEN           :: 55;
    KEY_EIGHT           :: 56;
    KEY_NINE            :: 57;
    KEY_SEMICOLON       :: 59;
    KEY_EQUAL           :: 61;
    KEY_A               :: 65;
    KEY_B               :: 66;
    KEY_C               :: 67;
    KEY_D               :: 68;
    KEY_E               :: 69;
    KEY_F               :: 70;
    KEY_G               :: 71;
    KEY_H               :: 72;
    KEY_I               :: 73;
    KEY_J               :: 74;
    KEY_K               :: 75;
    KEY_L               :: 76;
    KEY_M               :: 77;
    KEY_N               :: 78;
    KEY_O               :: 79;
    KEY_P               :: 80;
    KEY_Q               :: 81;
    KEY_R               :: 82;
    KEY_S               :: 83;
    KEY_T               :: 84;
    KEY_U               :: 85;
    KEY_V               :: 86;
    KEY_W               :: 87;
    KEY_X               :: 88;
    KEY_Y               :: 89;
    KEY_Z               :: 90;

    // Function keys
    KEY_SPACE           :: 32;
    KEY_ESCAPE          :: 256;
    KEY_ENTER           :: 257;
    KEY_TAB             :: 258;
    KEY_BACKSPACE       :: 259;
    KEY_INSERT          :: 260;
    KEY_DELETE          :: 261;
    KEY_RIGHT           :: 262;
    KEY_LEFT            :: 263;
    KEY_DOWN            :: 264;
    KEY_UP              :: 265;
    KEY_PAGE_UP         :: 266;
    KEY_PAGE_DOWN       :: 267;
    KEY_HOME            :: 268;
    KEY_END             :: 269;
    KEY_CAPS_LOCK       :: 280;
    KEY_SCROLL_LOCK     :: 281;
    KEY_NUM_LOCK        :: 282;
    KEY_PRINT_SCREEN    :: 283;
    KEY_PAUSE           :: 284;
    KEY_F1              :: 290;
    KEY_F2              :: 291;
    KEY_F3              :: 292;
    KEY_F4              :: 293;
    KEY_F5              :: 294;
    KEY_F6              :: 295;
    KEY_F7              :: 296;
    KEY_F8              :: 297;
    KEY_F9              :: 298;
    KEY_F10             :: 299;
    KEY_F11             :: 300;
    KEY_F12             :: 301;
    KEY_LEFT_SHIFT      :: 340;
    KEY_LEFT_CONTROL    :: 341;
    KEY_LEFT_ALT        :: 342;
    KEY_LEFT_SUPER      :: 343;
    KEY_RIGHT_SHIFT     :: 344;
    KEY_RIGHT_CONTROL   :: 345;
    KEY_RIGHT_ALT       :: 346;
    KEY_RIGHT_SUPER     :: 347;
    KEY_KB_MENU         :: 348;
    KEY_LEFT_BRACKET    :: 91;
    KEY_BACKSLASH       :: 92;
    KEY_RIGHT_BRACKET   :: 93;
    KEY_GRAVE           :: 96;

    // Keypad keys
    KEY_KP_0            :: 320;
    KEY_KP_1            :: 321;
    KEY_KP_2            :: 322;
    KEY_KP_3            :: 323;
    KEY_KP_4            :: 324;
    KEY_KP_5            :: 325;
    KEY_KP_6            :: 326;
    KEY_KP_7            :: 327;
    KEY_KP_8            :: 328;
    KEY_KP_9            :: 329;
    KEY_KP_DECIMAL      :: 330;
    KEY_KP_DIVIDE       :: 331;
    KEY_KP_MULTIPLY     :: 332;
    KEY_KP_SUBTRACT     :: 333;
    KEY_KP_ADD          :: 334;
    KEY_KP_ENTER        :: 335;
    KEY_KP_EQUAL        :: 336;
    
    // Android key buttons
    KEY_BACK            :: 4;
    KEY_MENU            :: 82;
    KEY_VOLUME_UP       :: 24;
    KEY_VOLUME_DOWN     :: 25;
}

MouseButton :: enum {
    MOUSE_LEFT_BUTTON   :: 0;
    MOUSE_RIGHT_BUTTON  :: 1;
    MOUSE_MIDDLE_BUTTON :: 2;
}

MouseCursor :: enum {
    MOUSE_CURSOR_DEFAULT       :: 0;
    MOUSE_CURSOR_ARROW         :: 1;
    MOUSE_CURSOR_IBEAM         :: 2;
    MOUSE_CURSOR_CROSSHAIR     :: 3;
    MOUSE_CURSOR_POINTING_HAND :: 4;
    MOUSE_CURSOR_RESIZE_EW     :: 5;     // The horizontal resize/move arrow shape
    MOUSE_CURSOR_RESIZE_NS     :: 6;     // The vertical resize/move arrow shape
    MOUSE_CURSOR_RESIZE_NWSE   :: 7;     // The top-left to bottom-right diagonal resize/move arrow shape
    MOUSE_CURSOR_RESIZE_NESW   :: 8;     // The top-right to bottom-left diagonal resize/move arrow shape
    MOUSE_CURSOR_RESIZE_ALL    :: 9;     // The omni-directional resize/move cursor shape
    MOUSE_CURSOR_NOT_ALLOWED   :: 10;
}

GamepadButton :: enum {
    // This is here just for error checking
    GAMEPAD_BUTTON_UNKNOWN :: 0;

    // This is normally a DPAD
    GAMEPAD_BUTTON_LEFT_FACE_UP;
    GAMEPAD_BUTTON_LEFT_FACE_RIGHT;
    GAMEPAD_BUTTON_LEFT_FACE_DOWN;
    GAMEPAD_BUTTON_LEFT_FACE_LEFT;

    // This normally corresponds with PlayStation and Xbox controllers
    // XBOX: [Y;X;A;B]
    // PS3: [Triangle;Square;Cross;Circle]
    // No support for 6 button controllers though..
    GAMEPAD_BUTTON_RIGHT_FACE_UP;
    GAMEPAD_BUTTON_RIGHT_FACE_RIGHT;
    GAMEPAD_BUTTON_RIGHT_FACE_DOWN;
    GAMEPAD_BUTTON_RIGHT_FACE_LEFT;

    // Triggers
    GAMEPAD_BUTTON_LEFT_TRIGGER_1;
    GAMEPAD_BUTTON_LEFT_TRIGGER_2;
    GAMEPAD_BUTTON_RIGHT_TRIGGER_1;
    GAMEPAD_BUTTON_RIGHT_TRIGGER_2;

    // These are buttons in the center of the gamepad
    GAMEPAD_BUTTON_MIDDLE_LEFT;     // PS3 Select
    GAMEPAD_BUTTON_MIDDLE;          // PS Button/XBOX Button
    GAMEPAD_BUTTON_MIDDLE_RIGHT;    // PS3 Start

    // These are the joystick press in buttons
    GAMEPAD_BUTTON_LEFT_THUMB;
    GAMEPAD_BUTTON_RIGHT_THUMB;
}

GamepadAxis :: enum {
    // Left stick
    GAMEPAD_AXIS_LEFT_X :: 0;
    GAMEPAD_AXIS_LEFT_Y :: 1;

    // Right stick
    GAMEPAD_AXIS_RIGHT_X :: 2;
    GAMEPAD_AXIS_RIGHT_Y :: 3;

    // Pressure levels for the back triggers
    GAMEPAD_AXIS_LEFT_TRIGGER :: 4;      // [1..-1] (pressure-level)
    GAMEPAD_AXIS_RIGHT_TRIGGER :: 5;
}



#scope_file
#import "Input";
