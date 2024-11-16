// voxel

// constants
VOXEL_SIZE         : float : .08;
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

populate_chunk :: (chunk : *VoxelChunkData, position : Vector3, seed : int) {
    using chunk;
    
    count : int = 0;
    for y : 0..CHUNK_SIZE_PADDED - 1 {
        for x : 0..CHUNK_SIZE_PADDED - 1 {
            for z : 0..CHUNK_SIZE_PADDED - 1 {
                pos : Vector3 = .{xx (x + (position.x * CHUNK_SIZE)), 
                                  xx (y + (position.y * CHUNK_SIZE)), 
                                  xx (z + (position.z * CHUNK_SIZE)),
                                  };
                                
                
                height : float = ((sin(pos.z / 10) * cos(pos.x / 10)) + 2) * 10;
                //height : float = get_2d(pos.x, pos.z, .05, 10, seed) * 32;
                
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

