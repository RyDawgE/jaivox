GLOBAL_ILLUMINATION_POINT : Vector3 : .{25, 100, 25};

RENDER_NAMES := string.[
    "Vulkan",
    "OpenGL",
];

RenderEngine :: enum u8 {
    VULKAN :: 0;
    OPENGL :: 1;
}

WindowCreationInfo :: struct {
    width  : float    :  640;
    height : float    :  480;
    title  : string : "JaiDawgEngine - Renderer: %";
}

Vertex :: struct {
    position  : Vector3;
    normal    : Vector3;
    tex_coord : Vector2;
}

//@TODO: Depricate.
UniformBufferObject :: struct {
    model : Matrix4;
    view  : Matrix4;
    proj  : Matrix4;
}

ViewProjection :: struct {
    view  : Matrix4;
    proj  : Matrix4;
}

Camera :: struct {
    view : Matrix4;
    proj : Matrix4;
}

Model :: struct {
    vertices : [..] Vertex;
    indices  : [..] u32;
    vertex_attributes   : u32;
    vertex_buffer       : u32;
    index_buffer        : u32;
    texture_object      : u32;
}

Sprite :: struct {
    position            : Vector2 = .{0, 0};
    scale               : Vector2 = .{1, 1};
    rotation            : float   = 0;

    texture_data        : TextureData;
    shader_program      : u32 = 0;

    animation_frame     : s32 = 0;
}

Animator :: struct {
    sprite          : *Sprite;
    duration        : float;
    start_time      : Apollo_Time;
    interruptable   : bool = true;
    looping         : bool = false;
}

SAMPLE_VERTS : [..] Vertex = xx Vertex.[
    .{.{-.5, -.5, 0}, .{1, 0, 0}, .{0, 0}},
    .{.{ .5, -.5, 0}, .{0, 1, 0}, .{0, 1}},
    .{.{ .5,  .5, 0}, .{0, 0, 1}, .{1, 1}},
    .{.{-.5,  .5, 0}, .{1, 1, 1}, .{1, 0}},
];

SAMPLE_INDXS : [..] u32 = xx u32.[
    0, 1, 2,
    2, 3, 0
];

SPRITE_QUAD : [..] Vector4 = xx Vector4.[
    .{0.0, 1.0, 0.0, 1.0},
    .{1.0, 0.0, 1.0, 0.0},
    .{0.0, 0.0, 0.0, 0.0},

    .{0.0, 1.0, 0.0, 1.0},
    .{1.0, 1.0, 1.0, 1.0},
    .{1.0, 0.0, 1.0, 0.0},
];

create_game_window :: () {
    window_width  : float  : WindowCreationInfo.width;
    window_height : float  : WindowCreationInfo.height;
    window_title  : string : WindowCreationInfo.title;

    game_state.render_handle.window = xx create_window(xx window_width, xx window_height,
                                                    tprint(window_title, RENDER_NAMES[RENDERER]),
                                                    wanted_msaa = 0);

    return;
}

create_render_engine :: () {
    create_game_window();
    initialize_render(game_state.render_handle);
}

cleanup_render_engine :: () {
    using game_state.render_handle;

    cleanup_render();
}

play_sprite_animation :: (entity : *Entity, sprite : *Sprite, duration : float, looping : bool = false, interruptable : bool = true) {
    if (entity.animator) {
        if !entity.animator.interruptable then return;
        cleanup_animator(entity.animator);
    }

    // entity.sprite.scale = scale;
    // entity.sprite.animating = true;

    entity.animator                 = New(Animator);
    entity.animator.start_time      = current_time_monotonic();
    entity.animator.sprite          = sprite;
    entity.animator.interruptable   = interruptable;
    entity.animator.duration        = duration;
    entity.animator.looping         = looping;

    return;
}

// I'm pretty sure this fucking sucks
cleanup_animator :: (animator : *Animator) -> *Animator {
    free(animator.sprite);
    free(animator);
    return null;
}

set_sprite_texture :: (sprite : *Sprite, texture : TextureData) {
        sprite.texture_data      = texture;
        scale : Vector2 = .{
            xx (texture.x / texture.anim_data.frames),
            xx texture.y
        };
        sprite.scale = scale;
}

register_model :: () {}

#if cast (RenderEngine) RENDERER ==  {
    case .OPENGL;
        #load "./opengl/opengl_engine.jai";
    case .VULKAN;
        #load "./vulkan/vulkan_engine.jai";

    case;
        #run print("invalid renderer argument supplied: %\n", RENDERER);
        #run assert(false);
}

#scope_file
#import "Window_Creation";
#import "File";
#load "texture.jai";
#load "textures.jai";

