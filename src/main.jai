game_state : GameState = .{};

main :: () {
    start_game();     
}

#load "./game/game.jai";
#load "./entity/entity.jai";
#load "./render/render_context.jai";

#import "Basic";
#import "Math";
#import "Bit_Operations";
#import "Compiler";

#if OS ==  {
  case .WINDOWS; hello_world :: () { #load "./render/platforms/windows.jai"; }
  case .MACOS;   hello_world :: () { print("mac!\n"); }
}