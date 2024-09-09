#import "Compiler";
#import "Basic";
#import "File";

build :: () {
    w := compiler_create_workspace();
    if !w {
        print("Compiler workspace creation failed.\n");
        return;
    }

    assert(w != 0);

    make_directory_if_it_does_not_exist("build_debug");

    options := get_build_options(w);
    options.output_executable_name = "jaivox";
    options.output_path = "./build_debug";

    set_build_options(options, w);

    import_path: [..] string;
    array_add(*import_path, "modules");
    array_add(*import_path, ..options.import_path);
    options.import_path = import_path;

    add_build_file(tprint("%src/main.jai", #filepath), w);

    set_build_options_dc(.{do_output=false});
    

}

main :: () {}

#run build();