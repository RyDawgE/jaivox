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
MAX_LOD_GROUPS      : u8        : 4;

VoxelChunkLOD :: enum_flags u8
{
    NOLOD_BIT :: 0b00000001;
    NRLOD_BIT :: 0b00000010;
    FRLOD_BIT :: 0b00000100;
    HMLOD_BIT :: 0b00001000;
} 

VoxelChunkData :: struct {
    id              : u64           = 0;
    data            : *u8           = null; //Where stored voxel data should go. 
    coordinate      : Vector3       = .{};
    lod             : VoxelChunkLOD = 1;
    mesh            : *Model        = null;
}

VoxelChunkMemoryBlock :: struct {
    data    : *VoxelChunkData = null;
    slots   : u64 = 0;
    full    : u64 = 0;
}

VoxelLODGroup :: struct {
    blocks          : [] VoxelChunkMemoryBlock;
    lod             : VoxelChunkLOD             = 0;
    voxel_data      : *u8                       = null; //Starting mem location of ALL voxels
    chunk_data      : *VoxelChunkData           = null; //Starting mem location of ALL chunks
}

VoxelWorldHandle :: struct {
    lod_groups      : [] VoxelLODGroup;   
    render_distance : int = 256;
}

get_lod_area :: (lod : VoxelChunkLOD, rd : float) -> int {
    if lod == {
        case .NOLOD_BIT; return 32;
        case .NRLOD_BIT; return cast (int) floor(PI * pow((rd/8) + 32, 2));
        case .FRLOD_BIT; return cast (int) floor(PI * pow((rd/8) + 32, 2));
        case .HMLOD_BIT; return cast (int) floor(PI * pow(rd, 2) - floor(PI * pow((rd/4) + 32, 2)));
        case; return 32;
    }
}

initialize_voxel_world :: () {
    using game_state.voxel_handle;
    
    array_resize(*lod_groups, MAX_LOD_GROUPS);
    for *group : lod_groups {
        group.lod = cast (VoxelChunkLOD) (1 << it_index);
        
        lod_factor : int = (bit_scan_reverse(group.lod) + 1);
        cs_p : int = CHUNK_SIZE_PADDED / lod_factor;
        cv : int = cs_p * cs_p * cs_p;
    
        num_chunks  : int  = get_lod_area(group.lod, cast (float) render_distance);
        array_resize(*group.blocks, num_chunks / 64);
        group.chunk_data = alloc(num_chunks * size_of(VoxelChunkData));
        group.voxel_data = alloc(num_chunks * cv);
        
        print("Group: %, Chunks: % (% Bytes), Voxels: % (% Bytes)\n", 
            it_index, 
            num_chunks, 
            num_chunks * size_of(VoxelChunkData), 
            num_chunks * (cv), 
        );
    }
}