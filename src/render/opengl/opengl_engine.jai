// opengl

#scope_file
DEFAULT_BACKGROUND : TextureData;
#scope_export

RenderHandle :: struct {
    window                     : Window_Type;
    instance                   : *void                    = null;
    default_shader_program     : u32;
    entity_vertex_attributes   : u32;
    IBO                        : u32;
    UBO                        : u32;
    bound_camera               : *Entity                  = null;
    sprite_vbo                 : u32;

    background_vbo             : u32;
    background_vao             : u32;
    background_sprite          : *Sprite                  = null;

    shader_objects             : *Table(string, u32);

    subscribed_entities        : [..] u64;
}

GameStateUniform :: struct {
    projection  : Matrix4;
    frame       : u32;
    time        : float;
    dt          : float;
}

// Currently broken when rendering both Entities and Voxels
USE_INDIRECTION : bool  = false;
MSAA_LEVEL      : s32   = 2;

initialize_render :: (render_handle : *RenderHandle) {
    create_opengl_context();
    create_shader_programs();
    create_attribute_descriptors();
    create_uniform_buffer_object();
    #if ENGINE2D {
        create_sprite_vertex_buffer();
        create_background();
    }
}

create_opengl_context :: () {
    using game_state.render_handle;
    using WindowCreationInfo;

    gl_create_context(window, 4, 3, false, DEBUG, MSAA_LEVEL);
    gl_load(*gl);

    gl_enable_debug_output(true);

    glViewport(0, 0, xx width, xx height);

    glEnable(GL_CULL_FACE);
    //glEnable(GL_DEPTH_TEST);
    glEnable(GL_MULTISAMPLE);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glDebugMessageCallback(debug_message_callback,xx  0);
}

create_shader_programs :: () {
    using game_state.render_handle;
    shader_objects = New(Table(string, u32));
    create_shader_objects();

    sprite_vshader := get_shader_object("SPRITE_VERT");
    sprite_fshader := get_shader_object("ANIMATED_SPRITE_FRAG");
    // If an entity shader program is 0, it will default to this.
    default_shader_program = create_shader_program(sprite_vshader, sprite_fshader);
}

create_attribute_descriptors :: () {
    using game_state.render_handle;

    // I'll be honest, im still not sure what this does.
    glGenVertexArrays(1, *entity_vertex_attributes);
    glBindVertexArray(entity_vertex_attributes);
}

create_uniform_buffer_object :: () {
    using game_state.render_handle;

    glGenBuffers(1, *UBO);
    glBindBuffer(GL_UNIFORM_BUFFER, UBO);
    glBufferData(GL_UNIFORM_BUFFER, size_of(GameStateUniform), null, GL_STATIC_DRAW);
    glBindBufferBase(GL_UNIFORM_BUFFER, 0, UBO);
}

create_sprite_vertex_buffer :: () {
    using game_state.render_handle;

    glGenBuffers(1, *sprite_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, sprite_vbo);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector4) * SPRITE_QUAD.count, SPRITE_QUAD.data, GL_STATIC_DRAW);

    glBindVertexArray(entity_vertex_attributes);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 4 * size_of(float), cast(*void) 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

create_background :: () {
    using game_state.render_handle;
    using WindowCreationInfo;

    DEFAULT_BACKGROUND = create_texture_animated(TEX_UNDEFINED, 1);

    glGenVertexArrays(1, *background_vao);
    glBindVertexArray(background_vao);

    glGenBuffers(1, *background_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, background_vbo);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector4) * BG_QUAD.count, BG_QUAD.data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 4 * size_of(float), cast(*void) 0);

    background_sprite = New(Sprite);
    background_sprite.scale = .{
        width,
        height
    };

    set_sprite_texture(background_sprite, DEFAULT_BACKGROUND);
}

draw_background :: () {
    using game_state.render_handle;
    glBindVertexArray(background_vao);

    glEnableVertexAttribArray(0);

    transform : Matrix4;
    pos       : Vector3 = .{0, 0, 0};
    scl       : Vector3 = .{640, 480, 1};
    qrot      : Quaternion;

    transform = make_translation_matrix4(.{0.0, 0.0, 0.0});
    transform = transform * make_scale_matrix4(scl);

    program : u32 = ifx background_sprite.shader_program != 0 then background_sprite.shader_program else default_shader_program;

    glUseProgram(program);

    model_loc := glGetUniformLocation(program, "model");
    glUniformMatrix4fv(model_loc, 1, GL_FALSE, *transpose(transform).coef[0][0]);

    curr_frame_loc := glGetUniformLocation(program, "curr_frame");
    glUniform1iv(curr_frame_loc, 1, *background_sprite.animation_frame);

    num_frames_loc := glGetUniformLocation(program, "num_frames");
    glUniform1iv(num_frames_loc, 1, *background_sprite.texture_data.anim_data.frames);

    glBindBuffer(GL_ARRAY_BUFFER, background_vbo);
    glBindTexture(GL_TEXTURE_2D, background_sprite.texture_data.texture_object);

    glDrawArrays(GL_TRIANGLES, 0, 6);
}

set_background_texture :: (bg : TextureData) {
    using game_state.render_handle;
    set_sprite_texture(background_sprite, bg);
}

swap_buffers :: (window: Window_Type, vsync := true) {  //@TODO: Implement other platforms and vsync
    #if OS == .WINDOWS {
        dc := GetDC(window);
        SwapBuffers(dc);
    }
}

draw_entities :: () {
    using game_state.render_handle;

    // Once per frame
    glBindVertexArray(entity_vertex_attributes);

    glEnableVertexAttribArray(0);

    //@TODO: Filter this out by entities that actually need rendering.
    //This should be for each model, rather than each entity. Each model would
    //Have a reference to every entity that uses it, or at least the transform of such.

    transform : Matrix4;
    pos       : Vector3 = .{0, 0, 0};
    scl       : Vector3 = .{1, 1, 1};
    qrot      : Quaternion;

    for id : subscribed_entities {
        entity : *Entity = get_entity(id);
        if !entity then continue;

        sprite          : *Sprite = null;
        texture_object, shader_program  : u32;
        current_frame,  num_frames      : s32;

        sprite, texture_object, shader_program, current_frame, num_frames =
            get_entity_render_info(entity);

        pos = .{
            entity.position.x + sprite.position.x,
            entity.position.y + sprite.position.y,
            0
        };
        scl = .{
            entity.scale.x * sprite.scale.x,
            entity.scale.y * sprite.scale.y,
            1,
        };

         //translate
        transform = make_translation_matrix4(pos);

        //rotate (move origin to center, rotate, move origin back to 0,0)
        //transform = transform * make_translation_matrix4(.{0.5 * scl.x, 0.5 * scl.y, 0.0});
        transform = transform * make_translation_matrix4(.{-0.5 * scl.x, -0.5 * scl.y, 0.0});
        set_from_axis_and_angle(*qrot, 0, 0, 1, radians(entity.rotation));
        transform = transform * rotation_matrix(Matrix4, qrot);

        //scale
        transform = transform * make_scale_matrix4(scl);

        program : u32 = ifx shader_program != 0 then shader_program else default_shader_program;

        glUseProgram(program);

        model_loc := glGetUniformLocation(program, "model");
        glUniformMatrix4fv(model_loc, 1, GL_FALSE, *transpose(transform).coef[0][0]);

        curr_frame_loc := glGetUniformLocation(program, "curr_frame");
        glUniform1iv(curr_frame_loc, 1, *current_frame);

        num_frames_loc := glGetUniformLocation(program, "num_frames");
        glUniform1iv(num_frames_loc, 1, *num_frames);


        // Begin Render
        glBindBuffer(GL_ARRAY_BUFFER, sprite_vbo);
        glBindTexture(GL_TEXTURE_2D, texture_object);

        glDrawArrays(GL_TRIANGLES, 0, 8*8*6);
    }
}

get_entity_render_info :: (entity : *Entity) -> *Sprite, u32, u32, s32, s32 {
    //Return order: sprite, texture_object, shader_program, current_frame, num_frames
    texture_object             : u32;
    shader_program             : u32;
    current_frame, num_frames  : s32;
    sprite                     : *Sprite = null;
    use_animator               : bool    = false;

    if (!entity) then return null,0,0,0,0;

    sprite = entity.sprite;
    if (entity.animator != null) {
        sprite = entity.animator.sprite;
        use_animator = true;
    }

    texture_object = sprite.texture_data.texture_object;
    num_frames = sprite.texture_data.anim_data.frames;
    shader_program = sprite.shader_program;

    // Calculate current animation frame
    if (use_animator) {
        delta_time := current_time_monotonic() - entity.animator.start_time;
        seconds : float64 = to_float64_seconds (delta_time);
        // I'll keep it a stack, idk how I figured this math out.. but it works. So I'm happy.
        duration_per_frame := entity.animator.duration / num_frames;
        current_frame = cast (s32) (seconds / duration_per_frame);
    } else {
        current_frame = sprite.animation_frame;
    }

    // This check is to see if the animation should end, if so
    // Delete the animator and revert back to rendering
    // with the entity sprite.
    if (use_animator) {
        if (current_frame == num_frames) {
            entity.animator = cleanup_animator(entity.animator);

            sprite = entity.sprite;
            use_animator = false;
            texture_object = sprite.texture_data.texture_object;
            num_frames = sprite.texture_data.anim_data.frames;
        } else {
            sprite = entity.animator.sprite;
            use_animator = true;
        }
    }

    return sprite, texture_object, shader_program, current_frame, num_frames;
}

create_texture :: (texture_memory : string) -> TextureData {
    using game_state.render_handle;
    texture_object : u32;

    glGenTextures(1, *texture_object);
    glBindTexture(GL_TEXTURE_2D, texture_object);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    buffer : [] u8;
    td : TextureData = load_texture_from_data (*buffer, texture_memory);
    defer unload_texture(buffer);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, cast (u32) td.x, cast (u32) td.y, 0, GL_RGBA, GL_UNSIGNED_BYTE, buffer.data);
    glGenerateMipmap(GL_TEXTURE_2D);

    td.texture_object = texture_object;

    return td;
}

create_texture_animated :: (texture_memory : string, num_frames : s32) -> TextureData {
    using game_state.render_handle;
    texture_object : u32;

    glGenTextures(1, *texture_object);
    glBindTexture(GL_TEXTURE_2D, texture_object);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    buffer : [] u8;
    td : TextureData = load_animated_texture_from_data (*buffer, texture_memory, num_frames);
    defer unload_texture(buffer);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, cast (u32) td.x, cast (u32) td.y, 0, GL_RGBA, GL_UNSIGNED_BYTE, buffer.data);
    glGenerateMipmap(GL_TEXTURE_2D);

    td.texture_object = texture_object;

    return td;
}

draw_frame :: () {
    using game_state.render_handle;

    glClearColor(.5, .5, 1, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glUseProgram(default_shader_program);

    proj := orthographic_projection_matrix(0.0, WindowCreationInfo.width, WindowCreationInfo.height, 0.0, -1, 1.0);

    state_uniform : GameStateUniform = .{
        transpose(proj),
        game_state.frame,
        game_state.time,
        game_state.delta_time,
    };

    glBindBuffer(GL_UNIFORM_BUFFER, UBO);
    glBufferData(GL_UNIFORM_BUFFER, size_of(GameStateUniform), *state_uniform, GL_STATIC_DRAW);

    draw_background();
    draw_entities();
    swap_buffers(window);
}

cleanup_render :: () {

}

debug_message_callback :: (source : GLenum, type : GLenum, id : GLuint, severity : GLenum, length : GLsizei, message : *u8, userParam : *void) -> void #c_call
{
    new_context : #Context;
    push_context new_context {
        print("GL CALLBACK: % type = %, severity = %, message = %\n", "foo", type, severity, to_string(message));
    }
}


#scope_file
#import "GL";
#import "Window_Creation";
#scope_file
#if OS == {
    case .WINDOWS;
        #load "opengl_windows.jai";
        #import "Windows";
    case;
}
#load "../shader.jai";
#load "../shaders.jai";