VoxelChunk :: struct @entity {
    using #as entity : Entity;
    
    voxel_data : *VoxelChunkData = null;
}

create_voxel_chunk :: (chunk : *VoxelChunk) {
    using chunk;
    
    voxel_data = New(VoxelChunkData);
    populate_chunk(voxel_data, position, cast (int) to_float64_seconds (current_time_monotonic()));
    mesh : *Model = binary_greedy_mesh(voxel_data);  
    model = mesh;
}

destroy_voxel_chunk :: (chunk : *VoxelChunk) {
    if chunk.voxel_data {
        free(chunk.voxel_data);
    }
}
