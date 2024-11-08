// voxel render

get_axis_index :: (axis : int, a : int, b : int, c : int) -> int {
    if (axis == 0) then return b + (a * CHUNK_SIZE_PADDED) + (c * CHUNK_SURFACE_AREA);
    else if (axis == 1) then return b + (c * CHUNK_SIZE_PADDED) + (a * CHUNK_SURFACE_AREA);
    else return c + (a * CHUNK_SIZE_PADDED) + (b * CHUNK_SURFACE_AREA);
}

naive_mesh :: (chunk : *VoxelChunk, model : *Model) {
     using chunk;
     using model;
     
     for voxel : voxels {
        
     }
}