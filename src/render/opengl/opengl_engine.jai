// opengl

RenderHandle :: struct {
    window                     : Window_Type;
    instance                   : *void                    = null;
    VBO                        : u32                      = 0;
    VAO                        : u32                      = 0;
    EBO                        : u32                      = 0;
    shader_program             : u32                      = 0;

}

initialize_render :: (render_handle : *RenderHandle) {
    create_opengl_context();
    create_shader_programs();
    create_vertex_buffer();
    
}

cleanup_render :: () {

}

create_opengl_context :: () {
    using game_state.render_handle;
    using WindowCreationInfo;
    
    gl_create_context(window,3, 3, false, DEBUG, 0);
    gl_load(*gl);
    
    gl_enable_debug_output(true);
    
    glViewport(0, 0, xx width, xx height);
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

create_vertex_buffer :: () {
    using game_state.render_handle; 
    
    glGenVertexArrays(1, *VAO);
    glGenBuffers(1, *VBO);
    glGenBuffers(1, *EBO);
    
    glBindVertexArray(VAO);
        
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    
    glBufferData(GL_ARRAY_BUFFER, size_of(Vertex) * VERTS.count, VERTS.data, GL_STATIC_DRAW);
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_TRUE, 6 * size_of(float), cast (*void) 0);
    glEnableVertexAttribArray(0);
    
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * size_of(float), cast(*void) (3 * size_of(float)));
    glEnableVertexAttribArray(1);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, xx INDICES.count * size_of(u16), INDICES.data, GL_STATIC_DRAW);
    
}

draw_frame :: () {
    using game_state.render_handle;

    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(shader_program);
    glBindVertexArray(VAO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glDrawElements(GL_TRIANGLES, xx INDICES.count, GL_UNSIGNED_SHORT, cast(*void) 0);
    
    swap_buffers(window);
}

swap_buffers :: (window: Window_Type, vsync := true) {  //@TODO: Implement other platforms and vsync
    #if OS == .WINDOWS {
        dc := GetDC(window);
        SwapBuffers(dc);
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
