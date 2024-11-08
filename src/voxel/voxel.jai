// voxel

// constants
VOXEL_SIZE         : u32 : 8;
CHUNK_SIZE         : u32 : 16;
AXIS_MASK          : u32 : 0b10000000000000000000000000000001;

// derived
CHUNK_SIZE_PADDED  : u32 : CHUNK_SIZE + 2;
CHUNK_SURFACE_AREA : u32 : CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED; 
CHUNK_VOLUME       : u32 : CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED;

VoxelChunk :: struct {
    voxels     : [CHUNK_VOLUME] u32;  
    heightmap  : [CHUNK_SURFACE_AREA] u32;
    location   : Vector3;
}

VoxelHandle :: struct {
    chunks : [..] VoxelChunk;
}

populate_chunk :: (chunk : *VoxelChunk) {
    using chunk;
    
    data : *u32 = voxels.data;
    for i : 0..CHUNK_SURFACE_AREA - 1 {
        voxel_position : Vector2 = .{ xx (i % CHUNK_SIZE_PADDED), xx (i / CHUNK_SIZE_PADDED) };
        height : u32 = 6; // Arbitrary, put the noise generator here!
        
        // This will fill all voxels below the generated height. Should generate a chunk based on a heightmap.
        index : u32 = (CHUNK_SURFACE_AREA * height) + (CHUNK_SURFACE_AREA - i);
        while (index / CHUNK_SURFACE_AREA) > 0 {
            voxels[index] = 1;
            index -= CHUNK_SURFACE_AREA;
        }
    }
    
    return;
}

