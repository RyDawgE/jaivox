create_shader_object :: (path : string, type : GLenum) -> u32 {
    using game_state.render_handle;
    file_location := tprint(path, get_program_data_dir());

    shader, shader_loaded := read_entire_file(file_location);

    shader_object : u32;
    shader_object = glCreateShader(type);
    glShaderSource(shader_object, 1, *shader.data, null);
    glCompileShader(shader_object);

    return shader_object;
}

create_shader_program :: (vertex_shader : u32, fragment_shader : u32) -> u32 {
    shader_program := glCreateProgram();

    glAttachShader(shader_program, vertex_shader);
    glAttachShader(shader_program, fragment_shader);
    glLinkProgram(shader_program);

    return shader_program;
}