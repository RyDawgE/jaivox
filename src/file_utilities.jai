get_program_data_dir :: () -> string {
    dir := trim_right(path_strip_filename(get_path_of_running_executable()), "/");
    return copy_string(dir);
}