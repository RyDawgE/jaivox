DEBUG := true;

#run build();

build :: () {
    w := compiler_create_workspace();
    if !w {
        print("Compiler workspace creation failed.\n");
        return;
    }

    assert(w != 0);

    options := get_build_options();
    options.output_executable_name = "jaivox";
    options.minimum_os_version = .{10, 13};
    args := options.compile_time_command_line;

    build_dir := "build_debug";

    set_build_options_dc(.{do_output=false});
    set_working_directory(#filepath);

    set_optimization(*options, .DEBUG);

    for arg: args {
        if arg == {
            case "release";
                DEBUG = false;
                build_dir = "build_release";
                set_optimization(*options, .VERY_OPTIMIZED);
                options.llvm_options.enable_split_modules = false;
                options.array_bounds_check        = .ON;
                options.null_pointer_check        = .ON;
                options.arithmetic_overflow_check = .OFF;
            case "debug";
            case "no_output";
                // useful if you want to compile to show errors, but not generate a build output
                // which saves compile time
                options.output_type = .NO_OUTPUT;
            case;
                compiler_report(tprint("Command-line argument #%, '%', is invalid. Valid options are: 'debug', 'release', 'no_output'.\n", it_index+1, arg));
        }
    }

    make_directory_if_it_does_not_exist(build_dir);

    options.output_path = build_dir;

    set_build_options(options, w);

    import_path: [..] string;
    array_add(*import_path, "modules");
    array_add(*import_path, ..options.import_path);
    options.import_path = import_path;

    // allows main program to use:
    // #if DEBUG
    build_constants := tprint(#string STRING
        DEBUG :: %;
    STRING,
        ifx DEBUG then "true" else "false",
    );

    add_build_string(build_constants, w);
    add_build_file(tprint("%src/main.jai", #filepath), w);

    compile_shaders(tprint("%/shaders", build_dir));
}

#import "Compiler";
#import "Basic";
#import "File";

#load "./compile_shaders.jai";
