VoxelChunk :: struct @entity {
    using #as entity : Entity;
    
    voxel_data : *VoxelChunkData = null;
}

create_voxel_chunk :: (chunk : *VoxelChunk) {
    using chunk;
    
    voxel_data = New(VoxelChunkData);
    populate_chunk(voxel_data, position, xx game_state.start_time);
    mesh : *Model = binary_greedy_mesh(voxel_data);  
    model = mesh;
}

destroy_voxel_chunk :: (chunk : *VoxelChunk) {
    if chunk.voxel_data {
        free(chunk.voxel_data);
    }
}
