VoxelChunk :: struct @entity {
    using #as entity : Entity;
    
    voxel_data : *VoxelChunkData = null;
}

create_voxel_chunk :: (chunk : *VoxelChunk, chunk_position : Vector3) {
    using chunk;
    
    voxel_data = New(VoxelChunkData);
    populate_chunk(voxel_data, chunk_position, xx game_state.start_time);
    mesh : *Model = binary_greedy_mesh(voxel_data);  
    model = mesh;
}

destroy_voxel_chunk :: (chunk : *VoxelChunk) {
    if chunk.voxel_data {
        free(chunk.voxel_data);
    }
}

populate_chunk :: (chunk : *VoxelChunkData, position : Vector3, seed : int) {
    using chunk;
    
    count : int = 0;
    for y : 0..CHUNK_SIZE_PADDED - 1 {
        for x : 0..CHUNK_SIZE_PADDED - 1 {
            for z : 0..CHUNK_SIZE_PADDED - 1 {
                pos : Vector3 = .{xx (x + CHUNK_SIZE * position.x), 
                                  xx (y + CHUNK_SIZE * position.y), 
                                  xx (z + CHUNK_SIZE * position.z),
                                  };
                                
                
                //height : float = ((sin(pos.z / 80) * cos(pos.x / 80)) + 2) * 10;
                height : float = get_2d(pos.x, pos.z, .01, 10, seed) * 32;
                
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


