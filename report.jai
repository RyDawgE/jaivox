test : [..] u8 : #run load_texture("path_to_some_texture.png");

TextureMemroyInfo :: struct {
    x : s32;
    y : s32;
    channels : s32;
    
    mem : *u8;
}

bake_texture :: (path : string) -> TextureMemoryInfo #compile_time {
    
}

load_texture :: (path : string) -> [..] u8 {
    asset_path := path;
    print("%\n", asset_path);

    file, success := file_open(asset_path);
    
    if !success {
        empty : [..] u8;
        return empty;
    }
    
    size : s64 = file_length(file);
    mem  : *u8;
    
    x,y,channels : s32;   
    
    buffer : [..] u8;
    
    buffer.data = stbi_load_from_file(*file, *x, *y, *channels, 4);
    
    return buffer;
}

main :: () {
    print("%\n", test.data);
}

#import "stb_image";
#import "Basic";
#import "File";