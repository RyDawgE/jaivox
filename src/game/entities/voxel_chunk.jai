VoxelChunk :: struct @entity {
    using #as entity : Entity;
    
    voxel_data  : *VoxelChunkData = null;
    voxel_model : *VoxelModel     = null;
}

create_voxel_chunk_data :: (chunk : *VoxelChunk, chunk_position : Vector3, lod : int = 1) {
    using chunk;    
    pos_lod : int = ifx lod != 0 then abs(lod) else 1;
    
    voxel_data = New(VoxelChunkData);
    
    // Maybe make initialize_chunk()?
    voxel_data.lod = pos_lod;
    voxel_data.location = chunk_position;
    
    populate_chunk(voxel_data, xx game_state.start_time);
}

destroy_voxel_chunk :: (chunk : *VoxelChunk) {
    if chunk.voxel_data {
        free(chunk.voxel_data);
    }
}

populate_chunk :: (chunk : *VoxelChunkData, seed : int) {  
    using chunk;
  
    cs    : int = CHUNK_SIZE / lod;
    
    cs_p  : int = cs + 2;
    cs_p2 : int = cs_p * cs_p;
    
    cs_ratio : float = (cast (float) cs / cast (float) CHUNK_SIZE);
    
    position : Vector3 = chunk.location;
    
    //chunk_erosion : float = get_2d(position.x, position.z, 1, 1, seed) * 10;
    
    //print("%\n", cs_ratio);
    
    for z : 0..cs_p - 1 {
        for x : 0..cs_p - 1 {
            pos2d : Vector2 = .{xx (x + cs * position.x), xx (z + cs * position.z)};
        
            height : float = get_2d(pos2d.x / cs_ratio, pos2d.y / cs_ratio, .01, 3, seed) * (cs);

            //height : float = ((sin(pos.z / 80) * cos(pos.x / 80)) + 2) * 10;
            
            for y : 0..cs_p - 1 {
                pos : Vector3 = .{pos2d.x, 
                                  xx (y + cs * position.y), 
                                  pos2d.y,
                                  };
                                                
                if xx pos.y <= height{
                    voxels[(y*cs_p2) + (x*cs_p) + (z)] = 1;
                }
            }
        }
    }
    return;
}


