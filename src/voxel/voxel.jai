// voxel

// constants
VOXEL_SIZE         : float : .1;
CHUNK_SIZE         : u32 : 30;
ULL1 : u64 : 1;

// derived
VOXEL_SCALE        : Vector3 : .{xx VOXEL_SIZE, xx VOXEL_SIZE, xx VOXEL_SIZE};
CHUNK_SCALE        : Vector3 : .{xx CHUNK_SIZE, xx CHUNK_SIZE, xx CHUNK_SIZE};
CHUNK_SIZE_PADDED  : u32 : CHUNK_SIZE + 2;
CHUNK_SURFACE_AREA : u32 : CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED; 
CHUNK_VOLUME       : u32 : CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED;
CS_LAST_BIT        : int : CHUNK_SIZE_PADDED - 1;
EDGE_MASK          : u64 : (ULL1 << CS_LAST_BIT) + ULL1;


VoxelChunkData :: struct {
    voxels     : [CHUNK_VOLUME] u32;  
    heightmap  : [CHUNK_SURFACE_AREA] u32;
    location   : Vector3;
}

VoxelHandle :: struct {
    chunks : [..] VoxelChunkData;
}
