VoxelChunk :: struct @entity {
    using #as entity : Entity;
}

create_voxel_chunk :: (chunk : *VoxelChunk) {
    using chunk;

    chunk_data : VoxelChunkData = .{};
    populate_chunk(*chunk_data, position, cast (int) to_float64_seconds (current_time_monotonic()));
    mesh : Model = binary_greedy_mesh(*chunk_data);  
    model = *mesh;
}
