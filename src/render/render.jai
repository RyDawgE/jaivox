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
    width  : float    :  1280;
    height : float    :  720;
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
    vertex_attributes  : u32;
    vertex_buffer      : u32;
    index_buffer       : u32;
    texture_object     : u32;
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

create_model_registry :: () {
    using game_state.render_handle;
    
    model_registry = New(Table(u32, Model));
}

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
    create_model_registry();
    create_game_window();
    initialize_render(game_state.render_handle);
}

cleanup_render_engine :: () {
    using game_state.render_handle;
    
    cleanup_render();
    deinit(model_registry);
    free(model_registry);
    
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
#load "../voxel/voxel_render.jai";
#load "texture.jai";
#load "textures.jai";

