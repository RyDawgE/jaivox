// voxel

// constants
VOXEL_SIZE          : float : .16;
CHUNK_SIZE          : u32 : 62;
ULL1                : u64 : 1;

// derived
VOXEL_SCALE         : Vector3   : .{xx VOXEL_SIZE, xx VOXEL_SIZE, xx VOXEL_SIZE};
CHUNK_SCALE         : Vector3   : .{xx CHUNK_SIZE, xx CHUNK_SIZE, xx CHUNK_SIZE};
CHUNK_WORLD_SCALE   : float     : VOXEL_SIZE * CHUNK_SIZE;
CHUNK_SIZE_PADDED   : u32       : CHUNK_SIZE + 2;
CHUNK_SURFACE_AREA  : u32       : CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED; 
CHUNK_VOLUME        : u32       : CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED;

MAX_LOD_DEFORM      : u8        : 0b00000010;

VoxelChunkData :: struct {
    voxels     : [] u8; // @TODO: Change to *u8  
    location   : Vector3;
    lod        : u8 = 1;
}

flatten_voxel_position :: (pos : Vector3, n : s32) -> s32 {
    n2 : s32 = n*n;
    n3 : s32 = n*n*n;
    
    return cast (s32) pos.x + (cast (s32) pos.y * n2) + (cast (s32) pos.z * n3);
}
