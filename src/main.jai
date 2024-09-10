main :: () {
    game_state : GameState = .{};

    start_game(*game_state);     
}

#load "./game/game.jai";
#load "./entity/entity.jai";
#load "./render/render_context.jai";

#import "Basic";
#import "Math";
#import "Bit_Operations";
#import "Compiler";
#import "GL";
#import "glfw";