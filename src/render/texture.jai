load_texture :: (path : string) -> *u8 {
    asset_path := tprint("%/..%", get_data_dir(), path);
    print("%\n", asset_path);

    file : File = file_open(asset_path);
    size : s64 = file_length(file);
    mem  : *u8;
    
    x,y,channels : s32;   
    
    mem = alloc(size);
    mem = stbi_load_from_file(*file, *x, *y, *channels, 3);
    
    return mem;
}

unload_texture :: (mem : *u8) {
    free(mem);
}

#import "stb_image";