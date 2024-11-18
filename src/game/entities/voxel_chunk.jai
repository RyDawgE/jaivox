VoxelChunk :: struct @entity {
    using #as entity : Entity;
    
    voxel_data : *VoxelChunkData = null;
}

create_voxel_chunk :: (chunk : *VoxelChunk, chunk_position : Vector3, lod : int = 1) {
    using chunk;
    
    print("%\n", lod);
    
    pos_lod : int = ifx lod != 0 then abs(lod) else 1;
    
    voxel_data = New(VoxelChunkData);
    populate_chunk(voxel_data, chunk_position, xx game_state.start_time, CHUNK_SIZE / pos_lod);
    mesh : *Model = binary_greedy_mesh(voxel_data, xx (CHUNK_SIZE / pos_lod), VOXEL_SIZE * pos_lod);  
    model = mesh;
}

destroy_voxel_chunk :: (chunk : *VoxelChunk) {
    if chunk.voxel_data {
        free(chunk.voxel_data);
    }
}

populate_chunk :: (chunk : *VoxelChunkData, position : Vector3, seed : int, cs : int = 30) {
    using chunk;
    
    cs_p : int = cs + 2;
    
    cs_ratio : float = (cast (float) cs_p / cast (float) CHUNK_SIZE_PADDED);
    
    //chunk_erosion : float = get_2d(position.x, position.z, 1, 1, seed) * 10;
    
    print("%\n", position);

    count : int = 0;
    for y : 0..cs_p - 1 {
        for x : 0..cs_p - 1 {
            for z : 0..cs_p - 1 {
                pos : Vector3 = .{xx (x + cs * position.x), 
                                  xx (y + cs * position.y), 
                                  xx (z + cs * position.z),
                                  };
                                
                
                //height : float = ((sin(pos.z / 80) * cos(pos.x / 80)) + 2) * 10;
                height : float = get_2d(pos.x / cs_ratio, pos.z / cs_ratio, .01, 2, seed) * (cs_p);
                
                //print("%\n", height);
                
                if xx pos.y <= height{
                    voxels[count] = 1;
                }
                count += 1;
            }
        }
    }
    return;
}


