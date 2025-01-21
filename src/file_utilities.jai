get_program_data_dir :: () -> string {
    dir := trim_right(path_strip_filename(get_path_of_running_executable()), "/");
    return copy_string(dir);
}

get_data_dir :: () -> string {
    dir := trim_right(path_strip_filename(get_path_of_running_executable()), "/");
    data_dir := trim_right(dir, "build_debug/");
    return copy_string(dir);
}