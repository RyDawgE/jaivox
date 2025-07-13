// opengl

RenderHandle :: struct {
    window                     : Window_Type;
    instance                   : *void                    = null;
    shader_program             : u32                      = 0;
    model_registry             : *Table(u32, Model);
    entity_vertex_attributes   : u32;
    IBO                        : u32;
    bound_camera               : *Entity                  = null;
    sprite_vbo                 : u32;

    subscribed_entities        : [..] u64;
}

// Currently broken when rendering both Entities and Voxels
USE_INDIRECTION : bool  = false;
MSAA_LEVEL      : s32   = 2;

initialize_render :: (render_handle : *RenderHandle) {
    create_opengl_context();
    create_shader_programs();
    create_attribute_descriptors();
    #if ENGINE2D {
        create_sprite_vertex_buffer();
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
    glCullFace(GL_BACK);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_MULTISAMPLE);
    glDebugMessageCallback(debug_message_callback,xx  0);
}

create_shader_programs :: () {
    using game_state.render_handle;
    vert_file_location := tprint("%/../src/shaders/sprite.vert", get_program_data_dir());
    frag_file_location := tprint("%/../src/shaders/sprite.frag", get_program_data_dir());

    vert, vert_loaded := read_entire_file(vert_file_location);
    frag, frag_loaded := read_entire_file(frag_file_location);

    vertex_shader : u32;
    vertex_shader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertex_shader, 1, *vert.data, null);
    glCompileShader(vertex_shader);

    fragment_shader : u32;
    fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragment_shader, 1, *frag.data, null);
    glCompileShader(fragment_shader);

    shader_program = glCreateProgram();

    glAttachShader(shader_program, vertex_shader);
    glAttachShader(shader_program, fragment_shader);
    glLinkProgram(shader_program);

    glDeleteShader(vertex_shader);
    glDeleteShader(fragment_shader);

}

create_attribute_descriptors :: () {
    using game_state.render_handle;

    glGenVertexArrays(1, *entity_vertex_attributes);
    glBindVertexArray(entity_vertex_attributes);

}

create_sprite_vertex_buffer :: () {
    using game_state.render_handle;

    glGenBuffers(1, *sprite_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, sprite_vbo);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector4) * SPRITE_QUAD.count, SPRITE_QUAD.data, GL_STATIC_DRAW);

    glBindVertexArray(entity_vertex_attributes);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 4 * size_of(float), cast(*void) 0);
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

        if !entity.sprite {
            continue;
        }

        //print("Entity: %\n", entity);
        pos = .{entity.position.x, entity.position.y, 0};
        scl = .{entity.scale.x, entity.scale.y, 1};

         //translate
        transform = make_translation_matrix4(pos);

        //rotate (move origin to center, rotate, move origin back to 0,0)
        transform = transform * make_translation_matrix4(.{0.5 * entity.scale.x, 0.5 * entity.scale.y, 0.0});
        set_from_axis_and_angle(*qrot, 0, 0, 1, radians(entity.rotation));
        transform = transform * rotation_matrix(Matrix4, qrot);
        transform = transform * make_translation_matrix4(.{-0.5 * entity.scale.x, -0.5 * entity.scale.y, 0.0});

        //scale
        transform = transform * make_scale_matrix4(scl);

        model_location := glGetUniformLocation(shader_program, "model");
        glUniformMatrix4fv(model_location, 1, GL_FALSE, *transpose(transform).coef[0][0]);


        // Begin Render
        glBindBuffer(GL_ARRAY_BUFFER, sprite_vbo);
        glBindTexture(GL_TEXTURE_2D, entity.sprite.texture_object);
        print("Tex: %\n", entity.sprite.texture_object);

        glDrawArrays(GL_TRIANGLES, 0, 6);
    }

}

create_texture :: (texture_memory : string) -> u32 {
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

    return texture_object;
}

handle_lighting :: () {
    using game_state.render_handle;

    light_uniform := glGetUniformLocation(shader_program, "lightPos");
    point := GLOBAL_ILLUMINATION_POINT;
    glUniform3f(light_uniform, point.x, point.y, point.z);
}

draw_frame :: () {
    using game_state.render_handle;

    glClearColor(.5, .5, 1, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glUseProgram(shader_program);

    proj := orthographic_projection_matrix(0.0, WindowCreationInfo.width, WindowCreationInfo.height, 0.0, -1, 1.0);

    projection_location := glGetUniformLocation(shader_program, "proj");
    glUniformMatrix4fv(projection_location, 1, GL_FALSE, *transpose(proj).coef[0][0]);

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
