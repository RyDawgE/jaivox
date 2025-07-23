create_shader_object :: (path : string, type : GLenum) -> u32 {
    using game_state.render_handle;
    file_location := tprint(path, get_program_data_dir());

    shader, shader_loaded := read_entire_file(file_location);

    shader_log : [1024] u8; //TODO find out if this is a heap allocation
    log_size   : u32 = 0;

    shader_object : u32;
    shader_object = glCreateShader(type);

    glShaderSource(shader_object, 1, *shader.data, null);
    glCompileShader(shader_object);

    glGetShaderInfoLog(shader_object, 1024, *log_size, shader_log.data);

    assert(log_size == 0, cast(string) tprint("\nError while compiling shader:\nPath: %\nError: %\n", path, cast(string) shader_log));

    return shader_object;
}

create_shader_program :: (vertex_shader : u32, fragment_shader : u32, delete_objects : bool = false) -> u32 {
    shader_program := glCreateProgram();

    glAttachShader(shader_program, vertex_shader);
    glAttachShader(shader_program, fragment_shader);
    glLinkProgram(shader_program);

    if (delete_objects) {
        glDeleteShader(vertex_shader);
        glDeleteShader(fragment_shader);
    }

    return shader_program;
}

define_shader :: (name : string, type : GLenum, path : string) {
    using game_state.render_handle;

    shader : u32 = create_shader_object(path, type);
    table_add(shader_objects, name, shader);
};

get_shader_object :: (name : string) -> u32 {
    using game_state.render_handle;

    shader_object, success := table_find(shader_objects, name);

    return ifx success then shader_object else 0;
};