// voxel

// constants
VOXEL_SIZE         : u32 : 8;
CHUNK_SIZE         : u32 : 30;
AXIS_MASK          : u32 : 0b10000000000000000000000000000001;

// derived
CHUNK_SIZE_PADDED  : u32 : CHUNK_SIZE + 2;
CHUNK_SURFACE_AREA : u32 : CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED; 
CHUNK_VOLUME       : u32 : CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED * CHUNK_SIZE_PADDED;

VoxelChunk :: struct {
    voxels     : [CHUNK_VOLUME] u32;  
    heightmap  : [CHUNK_SURFACE_AREA] u32;
}

VoxelHandle :: struct {
    chunks : [..] VoxelChunk;
}

