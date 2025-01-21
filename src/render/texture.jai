bake_texture :: (path : string) -> string, bool #compile_time {
    data, success := read_entire_file(path);
    
    assert(success, "Could not bake texture %\n");
    
    return data, success;
}

load_texture_from_data :: (buffer : *[]u8, data : string) {
    x, y, channels : s32;
    
    buffer.data = stbi_load_from_memory(data.data, data.count.(s32), *x, *y, *channels, 4);
    buffer.count = x * y * channels;
}

unload_texture :: (mem : []u8) {
    stbi_image_free(mem.data);
}

#import "stb_image";