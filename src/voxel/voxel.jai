// voxel

// constants
VOXEL_SIZE          : float : .16;
CHUNK_SIZE          : u32 : 62;
ULL1                : u64 : 1;

// derived
VOXEL_SCALE         : Vector3 : .{xx VOXEL_SIZE, xx VOXEL_SIZE, xx VOXEL_SIZE};
CHUNK_SCALE         : Vector3 : .{xx CHUNK_SIZE, xx CHUNK_SIZE, xx CHUNK_SIZE};
CHUNK_WORLD_SCALE   : float : VOXEL_SIZE * CHUNK_SIZE;
CHUNK_SIZE_PADDED   : u32 : CHUNK_SIZE + 2;
CHUNK_SURFACE_AREA  : u32 : CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED; 
CHUNK_VOLUME        : u32 : CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED;

VoxelChunkData :: struct {
    voxels     : [CHUNK_VOLUME] u8; // @TODO: Change to *u8  
    location   : Vector3;
    lod        : int = 1; // @TODO: Change to u8
}
