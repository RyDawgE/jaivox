VoxelChunk :: struct @entity {
    using #as entity : Entity;
    
    voxel_data  : *VoxelChunkData = null;
    voxel_model : *VoxelModel     = null;
}

init_voxel_chunk :: (entity : *VoxelChunk, coordinate : Vector3, lod : u8) {
    entity.position = .{coordinate.x, 0, coordinate.z} * CHUNK_WORLD_SCALE; 
    
    create_voxel_chunk_data(entity, coordinate, lod);
    create_voxel_model(game_state.render_handle.voxel_render_data, entity.id);
}

create_voxel_chunk_data :: (chunk : *VoxelChunk, chunk_position : Vector3, lod : u8 = 1) {
    using chunk;    
    
    //print("%\n", pos_lod);
    
    voxel_data = New(VoxelChunkData);
    voxel_data.lod = lod;
    voxel_data.location = chunk_position;
    
    populate_chunk(voxel_data, cast (int) game_state.start_time);
}

destroy_voxel_chunk :: (chunk : *VoxelChunk) {
    if chunk.voxel_data {
        array_free(chunk.voxel_data.voxels);
        free(chunk.voxel_data);
    }
}

populate_chunk :: (chunk : *VoxelChunkData, seed : int) {  
    using chunk;
    
    cs    : int = CHUNK_SIZE / lod;
    cs_p  : int = cs + 2;
    cs_p2 : int = cs_p * cs_p;
    cs_p3 : int = cs_p * cs_p * cs_p;

    array_resize(*voxels, cs_p3);
    
    cs_ratio : float = (cast (float) cs / cast (float) CHUNK_SIZE);
    c_position : Vector3 = chunk.location;
    
    for z : 0..cs_p - 1 {
        for x : 0..cs_p - 1 {
            pos2d : Vector2 = .{xx (x + cs * c_position.x), xx (z + cs * c_position.z)};
        
            height : float = get_2d(pos2d.x / cs_ratio, pos2d.y / cs_ratio, .005, 4, seed) * (cs);

            //height : float = ((sin(pos.z / 80) * cos(pos.x / 80)) + 2) * 10;
            
            for y : 0..cs_p - 1 {
                pos : Vector3 = .{pos2d.x, 
                                  cast (float) (y + cs * c_position.y), 
                                  pos2d.y,
                                  };
                                                
                if xx pos.y <= height{
                    voxels[(y*cs_p2) + (x*cs_p) + (z)] = 1;
                }
            }
        }
    }
    
    //print("Voxels: %\n", voxels);
    return;
}




