// opengl

RenderHandle :: struct {
    window                     : Window_Type;
    instance                   : *void                    = null;
    shader_program             : u32                      = 0;
    model_registry             : *Table(u32, Model);
    entity_vertex_attributes   : u32;
    voxel_vertex_attributes    : u32;
    bound_camera               : *Entity                  = null;
}

create_model :: (in_vertex_buffer : [..] Vertex, in_index_buffer : [..] u32) -> Model {
    //using game_state.render_handle; 
    
    model : Model = .{};
    
    VBO   : u32 = 0;
    EBO   : u32 = 0;
    
    glGenBuffers(1, *VBO);
    glGenBuffers(1, *EBO);
    
    vertex_buffer_size : s64 = in_vertex_buffer.count * size_of(Vertex);
    index_buffer_size  : s64 = in_index_buffer.count * size_of(u32);
    
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    
    glBufferData(GL_ARRAY_BUFFER, vertex_buffer_size, in_vertex_buffer.data, GL_STATIC_DRAW);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, index_buffer_size, in_index_buffer.data, GL_STATIC_DRAW);
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_TRUE,  6 * size_of(float), cast(*void) 0); // Position Attribute
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * size_of(float), cast(*void) (3 * size_of(float))); // Color Attribute  
    
    {
        using model;
        
        vertices = in_vertex_buffer;
        indices = in_index_buffer;
        vertex_buffer = VBO;
        index_buffer  = EBO;
    }
    
    return model;   
}

initialize_render :: (render_handle : *RenderHandle) {
    create_opengl_context();
    create_shader_programs();    
    create_attribute_descriptors();
}

cleanup_render :: () {

}

create_opengl_context :: () {
    using game_state.render_handle;
    using WindowCreationInfo;
    
    gl_create_context(window, 3, 3, false, DEBUG, 0);
    gl_load(*gl);
    
    gl_enable_debug_output(true);
    
    glViewport(0, 0, xx width, xx height);
    
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);    

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
    
    glEnable(GL_DEPTH_TEST);
}

create_attribute_descriptors :: () {
    using game_state.render_handle;
    
    glGenVertexArrays(1, *entity_vertex_attributes);       
    glGenVertexArrays(1, *voxel_vertex_attributes);
    
    glBindVertexArray(entity_vertex_attributes);
    
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
    glEnableVertexAttribArray(1);
    
    //@TODO: Filter this out by entities that actually need rendering.
    //This should be for each model, rather than each entity. Each model would
    //Have a reference to every entity that uses it, or at least the transform of such.
    
    // For each entity
    yaw   : Quaternion;
    pitch : Quaternion;
    roll  : Quaternion; // Unused! Implement me!
    
    rotation : Quaternion;
    
    transform : Matrix4;

    for block : game_state.entity_handle.entity_blocks {
        mask : u64 = block.member_mask;
        for i : 0..64 { 
            forward_bit : u64 = mask >> i;
            if forward_bit & 1 == 1 {
                entity : *Entity = xx (block.memory + (LARGEST_ENTITY_SIZE * i));
                
                //bad way to do it.
                if !entity.model {
                    continue;
                }
                
                // Begin transformation
                transform = Matrix4_Identity;
                
                set_from_axis_and_angle(*yaw, 0, 0, -1, radians(entity.rotation.x));
                set_from_axis_and_angle(*pitch, -1, 0, 0, radians(entity.rotation.y));
                
                rotation = yaw * pitch;
                
                transform = make_translation_matrix4(entity.position) * rotation_matrix(Matrix4, rotation);
                
                
                // Begin Render
                model_location := glGetUniformLocation(shader_program, "model");
                glUniformMatrix4fv(model_location, 1, GL_FALSE, *transform.coef[0][0]);
                
                glBindBuffer(GL_ARRAY_BUFFER, entity.model.vertex_buffer);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, entity.model.index_buffer);
                                
                glDrawElements(GL_TRIANGLES, xx entity.model.indices.count, GL_UNSIGNED_INT, cast(*void) 0);
            }    
        }
    }
}

draw_voxels :: () {
    
}


draw_frame :: () {
    using game_state.render_handle;

    view : Matrix4;

    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(shader_program);
    
    if bound_camera {
        yaw   : Quaternion;
        pitch : Quaternion;
        
        transform : Matrix4 = Matrix4_Identity;
        
        set_from_axis_and_angle(*yaw, 0, -1, 0, radians(bound_camera.rotation.x));
        set_from_axis_and_angle(*pitch, -1, 0, 0, radians(bound_camera.rotation.y));
        
        rotation : Quaternion = yaw * pitch;
        
        transform = make_translation_matrix4(bound_camera.position) * rotation_matrix(Matrix4, rotation);
        
        view = inverse(transform); //type mat4
    
        //view = make_look_at_matrix(bound_camera.position, .{0, 0, 0}, .{0, 0, 1}, false);
    } else {
        view = make_look_at_matrix(.{2, 2, 2}, .{0, 0, 0}, .{0, 0, 1}, false);
    }
    
    proj  := transpose(make_projection_matrix(45.0 * PI / 180.0, xx (640 / 480), 0.1, 100.0));
    
    view_location := glGetUniformLocation(shader_program, "view");
    glUniformMatrix4fv(view_location, 1, GL_FALSE, *transpose(view).coef[0][0]);
    
    projection_location := glGetUniformLocation(shader_program, "proj");
    glUniformMatrix4fv(projection_location, 1, GL_FALSE, *proj.coef[0][0]);
    
    draw_voxels();
    
    draw_entities();
    
    swap_buffers(window);
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
