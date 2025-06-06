// opengl

RenderHandle :: struct {
    window                     : Window_Type;
    instance                   : *void                    = null;
    shader_program             : u32                      = 0;
    model_registry             : *Table(u32, Model);
    entity_vertex_attributes   : u32;
    IBO                        : u32;
    bound_camera               : *Entity                  = null;

    voxel_render_data          : *VoxelWorldRenderData    = null;

    subscribed_entities        : [..] u64;
}

VoxelIndirectCommand :: struct {
    count           : u32;
    instance_count  : u32;
    first_index     : u32;
    base_vertex     : s32;
    base_instance   : u32;
}

// Currently broken when rendering both Entities and Voxels
USE_INDIRECTION : bool  = false;
MSAA_LEVEL      : s32   = 2;

create_model :: (in_vertex_buffer : [..] Vertex, in_index_buffer : [..] u32) -> *Model {
    model : *Model = New(Model);

    VBO   : u32 = 0;
    EBO   : u32 = 0;

    glGenBuffers(1, *VBO);
    glGenBuffers(1, *EBO);

    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);


    vertex_buffer_size : s64 = in_vertex_buffer.count * size_of(Vertex);
    index_buffer_size  : s64 = in_index_buffer.count * size_of(u32);

    glNamedBufferData(VBO, vertex_buffer_size, in_vertex_buffer.data, GL_DYNAMIC_DRAW);
    glNamedBufferData(EBO, index_buffer_size, in_index_buffer.data, GL_DYNAMIC_DRAW);

    {
        using model;

        vertices = in_vertex_buffer;
        indices = in_index_buffer;
        vertex_buffer = VBO;
        index_buffer  = EBO;
    }

    return model;
}

create_voxel_model :: (world_render : *VoxelWorldRenderData, chunk_id : u64) {
    using game_state.render_handle;

    chunk := cast (*VoxelChunk) get_entity(chunk_id);

    if (!chunk.voxel_data) {
            print("Bad Voxel Data during model creation.\n");
            return;
    }


    model : *VoxelModel = binary_greedy_mesh(world_render, chunk.voxel_data);
    model.texture_object = world_render.texture;
    chunk.voxel_model = model;

    array_add(*world_render.chunk_entity_ids, chunk.id);

    glNamedBufferSubData(world_render.VBO,
                         model.base_vertex * size_of(Vertex),
                         model.vertex_count * size_of(Vertex),
                         world_render.vertex_buffer.data + model.base_vertex
                         );

    //print("%\n", model.base_vertex);

    if USE_INDIRECTION {
        indirect_buffer : [..] VoxelIndirectCommand;

        for id : voxel_render_data.chunk_entity_ids {
            if chunk_id != id then continue;
            chunk : *VoxelChunk = cast(*VoxelChunk) get_entity(id);
            model : *VoxelModel = chunk.voxel_model;

            indirect : VoxelIndirectCommand = .{
                model.element_count,
                1,
                0,
                cast (s32) model.base_vertex,
                0
            };

            glBufferSubData(GL_DRAW_INDIRECT_BUFFER, size_of(VoxelIndirectCommand) * it_index, size_of(VoxelIndirectCommand), *indirect);

            array_add(*indirect_buffer, indirect);
        }

        //glBufferSubData(GL_DRAW_INDIRECT_BUFFER, size_of(VoxelIndirectCommand) * abs(flatten_voxel_position(chunk.voxel_data.location, 128)), size_of(VoxelIndirectCommand), *indirect);
    }
    // print("Chunk Buffer: %\n", model);
    // print("World Vertex Buffer Size: %mb\n", (size_of(Vertex) * world_render.vertex_buffer.count) / 1_000_000);

    return;
}

initialize_render :: (render_handle : *RenderHandle) {
    create_opengl_context();
    create_shader_programs();
    create_voxel_buffer();
    create_attribute_descriptors();
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
    vert_file_location := tprint("%/../src/shaders/shader.vert", get_program_data_dir());
    frag_file_location := tprint("%/../src/shaders/shader.frag", get_program_data_dir());

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
    glGenVertexArrays(1, *voxel_render_data.VAO);

    glBindVertexArray(entity_vertex_attributes);

}

create_voxel_buffer :: () {
    using game_state.render_handle;

    voxel_render_data = New(VoxelWorldRenderData);

    voxel_render_data.texture = create_texture(TEX_ENV_GRASS_62);

    array_reserve(*voxel_render_data.vertex_buffer, size_of(Vertex) * 10_000_000);

    glGenBuffers(1, *voxel_render_data.VBO);
    glGenBuffers(1, *voxel_render_data.EBO);
    glGenBuffers(1, *IBO);

    glBindBuffer(GL_ARRAY_BUFFER, voxel_render_data.VBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, voxel_render_data.EBO);
    glBindBuffer(GL_DRAW_INDIRECT_BUFFER, IBO);

    // Index buffer is always the same per indirect, so here I calculate the worst-case
    // scenario and upload it on startup.
    for i : 0..((CHUNK_SIZE / 2) * CHUNK_SIZE * CHUNK_SIZE * 6) - 1{
        array_add(*voxel_render_data.index_buffer, (i * 4) + 1);
        array_add(*voxel_render_data.index_buffer, (i * 4) + 2);
        array_add(*voxel_render_data.index_buffer, (i * 4) + 0);

        array_add(*voxel_render_data.index_buffer, (i * 4) + 2);
        array_add(*voxel_render_data.index_buffer, (i * 4) + 3);
        array_add(*voxel_render_data.index_buffer, (i * 4) + 0);
    }

    //print("%\n", voxel_render_data.index_buffer.count * size_of(u32) * 64);

    // Size of allocated space, in bytes
    vertex_buffer_size : s64 = voxel_render_data.vertex_buffer.allocated;
    index_buffer_size  : s64 = voxel_render_data.index_buffer.allocated;

    // Preallocate the data by sending the empty, reserved arrays.
    glBufferData(GL_ARRAY_BUFFER, vertex_buffer_size, voxel_render_data.vertex_buffer.data, GL_DYNAMIC_DRAW);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, index_buffer_size, voxel_render_data.index_buffer.data, GL_DYNAMIC_DRAW);

    if USE_INDIRECTION then glBufferData(GL_DRAW_INDIRECT_BUFFER, xx (RENDER_DISTANCE * RENDER_DISTANCE) * size_of(VoxelIndirectCommand), cast (*void) 0, GL_DYNAMIC_DRAW);

    //array_free(voxel_render_data.vertex_buffer);

}

swap_buffers :: (window: Window_Type, vsync := true) {  //@TODO: Implement other platforms and vsync
    #if OS == .WINDOWS {
        dc := GetDC(window);
        SwapBuffers(dc);
    }
}

draw_voxels_indirect :: () {
    using game_state.render_handle;

    glBindBuffer(GL_DRAW_INDIRECT_BUFFER, IBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, voxel_render_data.EBO);
    glBindBuffer(GL_ARRAY_BUFFER, voxel_render_data.VBO);

    glBindVertexArray(entity_vertex_attributes); // Make a voxel version of this later. Right now its exactly the same format

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);


    glVertexAttribPointer(0, 3, GL_FLOAT, GL_TRUE,  size_of(Vertex), cast(*void) 0); // Position Attribute
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void) (3 * size_of(float))); // Color Attribute
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void) (6 * size_of(float))); // Tex CoordAttribute

    transform := make_translation_matrix4(.{0, 0, 0});
    model_location := glGetUniformLocation(shader_program, "model");
    glUniformMatrix4fv(model_location, 1, GL_FALSE, *transpose(transform).coef[0][0]);

    glMultiDrawElementsIndirect(GL_TRIANGLES, GL_UNSIGNED_INT, cast (*void) 0, cast (u32) voxel_render_data.chunk_entity_ids.count, 0);
}

draw_voxels :: () {
    using game_state.render_handle;

    glBindVertexArray(entity_vertex_attributes); // Make a voxel version of this later. Right now its exactly the same format

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);

    glBindBuffer(GL_ARRAY_BUFFER, voxel_render_data.VBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, voxel_render_data.EBO);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_TRUE,  size_of(Vertex), cast(*void) 0); // Position Attribute
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void) (3 * size_of(float))); // Color Attribute
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void) (6 * size_of(float))); // Tex CoordAttribute

    // For each entity
    yaw   : Quaternion;
    pitch : Quaternion;
    roll  : Quaternion;

    rotation : Quaternion;

    transform : Matrix4;

    for id : voxel_render_data.chunk_entity_ids {
        chunk : *VoxelChunk = cast(*VoxelChunk) get_entity(id);
        model : *VoxelModel = chunk.voxel_model;

        // Begin transformation
        set_from_axis_and_angle(*yaw, 0, 0, -1, radians(chunk.rotation.x));
        set_from_axis_and_angle(*pitch, -1, 0, 0, radians(chunk.rotation.y));
        set_from_axis_and_angle(*roll, 0, -1, 0, radians(chunk.rotation.z));

        rotation = yaw * pitch * roll;

        transform = make_translation_matrix4(chunk.position) * rotation_matrix(Matrix4, rotation);

        model_location := glGetUniformLocation(shader_program, "model");
        glUniformMatrix4fv(model_location, 1, GL_FALSE, *transpose(transform).coef[0][0]);
        glBindTexture(GL_TEXTURE_2D, model.texture_object);

        glDrawElementsBaseVertex(GL_TRIANGLES, model.element_count, GL_UNSIGNED_INT, cast (*void) 0, xx (model.base_vertex));
    }
    //glMultiDrawElements(GL_TRIANGLES, xx voxel_render_data.chunk_entity_ids.count, GL_UNSIGNED_INT, cast (*void) 0, xx voxel_render_data.index_buffer.count);
    //glDrawElements(GL_TRIANGLES, 20000, GL_UNSIGNED_INT, cast (*void) 0 );

}

draw_entities :: () {
    using game_state.render_handle;

    // Once per frame
    glBindVertexArray(entity_vertex_attributes);

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);

    //@TODO: Filter this out by entities that actually need rendering.
    //This should be for each model, rather than each entity. Each model would
    //Have a reference to every entity that uses it, or at least the transform of such.

    // For each entity
    yaw   : Quaternion;
    pitch : Quaternion;
    roll  : Quaternion;

    rotation : Quaternion;

    transform : Matrix4;

    for id : subscribed_entities {
        entity : *Entity = get_entity(id);

        //bad way to do it.
        if !entity.model {
            continue;
        }

        //print("Entity: %\n", entity);

        // Begin transformation
        set_from_axis_and_angle(*yaw, 0, 0, -1, radians(entity.rotation.x));
        set_from_axis_and_angle(*pitch, -1, 0, 0, radians(entity.rotation.y));
        set_from_axis_and_angle(*roll, 0, -1, 0, radians(entity.rotation.z));

        rotation = yaw * pitch * roll;

        transform = make_translation_matrix4(entity.position) * rotation_matrix(Matrix4, rotation);

        // Begin Render
        glBindBuffer(GL_ARRAY_BUFFER, entity.model.vertex_buffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, entity.model.index_buffer);
        glBindTexture(GL_TEXTURE_2D, entity.model.texture_object);

        glVertexAttribPointer(0, 3, GL_FLOAT, GL_TRUE,  size_of(Vertex), cast(*void) 0); // Position Attribute
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void) (3 * size_of(float))); // Color Attribute
        glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void) (6 * size_of(float))); // Tex CoordAttribute

        model_location := glGetUniformLocation(shader_program, "model");
        glUniformMatrix4fv(model_location, 1, GL_FALSE, *transpose(transform).coef[0][0]);

        glDrawElements(GL_TRIANGLES, xx entity.model.indices.count, GL_UNSIGNED_INT, cast(*void) 0);
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

    view : Matrix4;

    glClearColor(.5, .5, 1, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glUseProgram(shader_program);

    if bound_camera {
        yaw   : Quaternion;
        pitch : Quaternion;
        roll  : Quaternion;

        transform : Matrix4 = Matrix4_Identity;

        set_from_axis_and_angle(*yaw, 0, -1, 0, radians(bound_camera.rotation.x));
        set_from_axis_and_angle(*pitch, -1, 0, 0, radians(bound_camera.rotation.y));
        set_from_axis_and_angle(*roll, 0, 0, -1, radians(bound_camera.rotation.z));

        rotation : Quaternion = yaw * pitch * roll;

        transform = make_translation_matrix4(bound_camera.position) * rotation_matrix(Matrix4, rotation);

        view = inverse(transform); //type mat4

        //view = make_look_at_matrix(bound_camera.position, .{0, 0, 0}, .{0, 0, 1}, false);
    } else {
        view = make_look_at_matrix(.{2, 2, 2}, .{0, 0, 0}, .{0, 0, 1}, false);
    }

    aspect_ratio : float = (WindowCreationInfo.width / WindowCreationInfo.height);

    proj  := transpose(make_projection_matrix(75.0 * PI / 180.0, aspect_ratio, 0.1, 10000.0, 0, 0, true));

    view_location := glGetUniformLocation(shader_program, "view");
    glUniformMatrix4fv(view_location, 1, GL_FALSE, *transpose(view).coef[0][0]);

    projection_location := glGetUniformLocation(shader_program, "proj");
    glUniformMatrix4fv(projection_location, 1, GL_FALSE, *proj.coef[0][0]);

    handle_lighting();

    if USE_INDIRECTION {
        draw_voxels_indirect();
    } else {
        draw_voxels();
    }
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
