main :: () {
    game_state : GameState = .{};

    start_game(*game_state);     
}

#load "./game/game.jai";
#load "./entity/entity.jai";

#import "Basic";
#import "Math";
#import "raylib";
#import "Bit_Operations";
#import "Compiler";
#import "GL";
#import "glfw";