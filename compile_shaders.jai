// This is not currently loaded by the Render module but is instead a utility file
// that can be separately loaded by metaprograms to build shaders

compile_shaders :: (output_directory: string) -> bool {
    base_directory := tprint("%src/shaders", #filepath);

    #if OS == .WINDOWS {
        shader_compiler := "glslc.exe";
    } else #if OS == .LINUX {
        // TODO
    } else #if OS == .MACOS {
        shader_compiler := tprint("%/bin/macos/glslc", base_directory);
    } else {
        #assert false "Vulkan shader compilation is not supported in this platform";
    }

    mono_output_directory := tprint("%/mono", output_directory);
    // stereo_output_directory := tprint("%/stereo", output_directory);
    if file_exists(mono_output_directory)   delete_directory(mono_output_directory);
    // if file_exists(stereo_output_directory) delete_directory(stereo_output_directory);
    make_directory_if_it_does_not_exist(mono_output_directory, recursive = true);
    // make_directory_if_it_does_not_exist(stereo_output_directory, recursive = true);

    for file_list(tprint("%", base_directory)) {
        if ends_with(it, ".vert") || ends_with(it, ".frag") {
            if !compile_shader(shader_compiler, it, "-DIS_STEREO=0", mono_output_directory) {
                return false;
            }
            // if !compile_shader(shader_compiler, it, "-DIS_STEREO=1", stereo_output_directory) {
            //     return false;
            // }
        }
    }

    log("Shader compilation succeeded");

    return true;
}

compile_shader :: (shader_compiler: string, shader_path: string, flags: string, output_directory: string) -> bool {
    filename := path_filename(shader_path);

    output_path := tprint("%/%.spv", output_directory, filename);
    compiler_command := string.[shader_compiler, shader_path, "-o", output_path, flags];
    log("Compiling % to % (%)", filename, output_path, get_quoted_command_string(compiler_command));
    result := run_command(..compiler_command);
    if result.exit_code != 0 {
        return false;
    }

    return true;
}

#import "Basic";
#import "File";
#import "File_Utilities";
#import "Process";
#import "String";
