// voxel render

binary_greedy_mesh :: (chunk : *VoxelChunk) -> Model {
    using chunk;
    
    vertices : [..] Vertex;
    indices  : [..] u32;
    
    array_reserve(*vertices, voxels.count * 4);
    array_reserve(*indices, indices.count * 6);
    
    axis_cols      : [CHUNK_SURFACE_AREA * 3] u64;
    col_face_masks : [CHUNK_SURFACE_AREA * 6] u64;
        
    voxel_index : s32 = 0;
    for y : 0..CHUNK_SIZE_PADDED - 1 {
        y_offset : int = (y * CHUNK_SIZE_PADDED) + CHUNK_SURFACE_AREA;
        for x : 0..CHUNK_SIZE_PADDED - 1 {
            zb : u64 = 0;
            for z : 0..CHUNK_SIZE_PADDED - 1 {
                if (voxels[voxel_index] & 1 == 1) { // if first bit == 1, voxel is occupied
                    axis_cols[x + (z * CHUNK_SIZE_PADDED)] |= ULL1 << y;
                    axis_cols[z + y_offset] |= ULL1 << x;
                    zb |= ULL1 << z;
                }         
                voxel_index += 1;
            }
            axis_cols[y + (x * CHUNK_SIZE_PADDED) + (CHUNK_SURFACE_AREA * 2)] = zb;
        }
    }
    
    for axis : 0..2 {
        for i : 0..CHUNK_SURFACE_AREA - 1 {
            col : u64 = axis_cols[(CHUNK_SURFACE_AREA * axis) + i];
            col_face_masks[(CHUNK_SURFACE_AREA * (axis * 2)) + i] = col & ~((col >> 1) | (ULL1 << CS_LAST_BIT));
            col_face_masks[(CHUNK_SURFACE_AREA * (axis * 2 + 1)) + i] = col & ~((col << 1) | ULL1);
        }
    }
    
    
    for face : 0..5 {
        axis : int = face / 2;
        facexCS_P2 : int = face * CHUNK_SURFACE_AREA;
        face_even_offset : int = ifx (face % 2 == 0) then 1 else 0; 
        
        merged_forward : [CHUNK_SURFACE_AREA] int;
        for forward : 1..CS_LAST_BIT - 1 {
            forwardxCS_PxfacexCS_P2 : int = (forward * CHUNK_SIZE_PADDED) + facexCS_P2;
            bits_walking_right : u64 = 0;
            merged_right : [CHUNK_SIZE_PADDED] int;
            forwardGteCS : bool = forward >= CHUNK_SIZE;
            
            for right : 1..CS_LAST_BIT - 1 {
                rightxCS_P : int = right * CHUNK_SIZE_PADDED;
                
                bits_here : u64 = col_face_masks[right + forwardxCS_PxfacexCS_P2] & ~EDGE_MASK;
                bits_merging_forward : u64 = ifx forwardGteCS then 0 else (bits_here & ~bits_walking_right & col_face_masks[right + forwardxCS_PxfacexCS_P2 + CHUNK_SIZE_PADDED]);
                
                //print("Merging Forward\n");
                copy_front : u64 = bits_merging_forward;
                while (copy_front) {
                    bit_pos : int = bit_scan_forward(copy_front) - 1; //Could cause problems
                    copy_front &= ~(ULL1 << bit_pos);
                    
                    merged_forward[rightxCS_P + bit_pos] += 1;
                }
                
                bits_merging_right : u64 = ifx right >= CHUNK_SIZE then 0 else (bits_here & (col_face_masks[right + 1 + forwardxCS_PxfacexCS_P2]));
                
                //print("Merging Right\n");
                bits_stopped_forward : u64 = bits_here & ~bits_merging_forward;
                while (bits_stopped_forward) {
                    //print("%\n", formatInt(bits_stopped_forward, 2));
                    bit_pos : int = bit_scan_forward(bits_stopped_forward) - 1;
                    bits_stopped_forward &= ~(ULL1 << bit_pos);
                    
                    shifted_pos : u64 = ULL1 << bit_pos;
                    if ((bits_merging_right & (shifted_pos)) && merged_forward[rightxCS_P + bit_pos] == merged_forward[(right + 1) * CHUNK_SIZE_PADDED + bit_pos]) {
                        bits_walking_right |= ULL1 << bit_pos;
                        merged_right[bit_pos] += 1;
                        merged_forward[rightxCS_P + bit_pos] = 0;
                        continue;
                    }
                    bits_walking_right &= ~(ULL1 << bit_pos);
                    
                    mesh_left   : float = xx (right - merged_right[bit_pos]);
                    mesh_right  : float = xx (right + 1);
                    mesh_front  : float = xx (forward - merged_forward[rightxCS_P + bit_pos]);
                    mesh_back   : float = xx (forward + 1);
                    mesh_up     : float = xx (bit_pos + face_even_offset);
                    
                    merged_forward[rightxCS_P + bit_pos] = 0;
                    merged_right[bit_pos] = 0;
                    
                    v1 : Vector3;
                    v2 : Vector3;
                    v3 : Vector3;
                    v4 : Vector3;
                    
                    vert1 : Vertex;
                    vert2 : Vertex;
                    vert3 : Vertex;
                    vert4 : Vertex;
                    
                    color : Vector3;
                    
                    // Front
                    if face == 0 {
                        v1 = .{mesh_left, mesh_up, mesh_front};
                        v2 = .{mesh_left, mesh_up, mesh_back};
                        v3 = .{mesh_right, mesh_up, mesh_back};
                        v4 = .{mesh_right, mesh_up, mesh_front};
                        
                        color = .{235, 64, 52} / .{255, 255, 255};
                        
                    // Back
                    } else if face == 1 {
                        v1 = .{mesh_left, mesh_up, mesh_back};
                        v2 = .{mesh_left, mesh_up, mesh_front};
                        v3 = .{mesh_right, mesh_up, mesh_front};
                        v4 = .{mesh_right, mesh_up, mesh_back}; 
                    
                        color = .{235, 64, 52} / .{255, 255, 255};
    
                    // Right
                    } else if face == 2 {
                        v1 = .{mesh_up, mesh_front, mesh_left};
                        v2 = .{mesh_up, mesh_back, mesh_left};
                        v3 = .{mesh_up, mesh_back, mesh_right};
                        v4 = .{mesh_up, mesh_front, mesh_right};

                        color = .{52, 235, 143} / .{255, 255, 255};;
                        
                    // Left
                    } else if face == 3 {
                        v1 = .{mesh_up, mesh_back, mesh_left};
                        v2 = .{mesh_up, mesh_front, mesh_left};
                        v3 = .{mesh_up, mesh_front, mesh_right};
                        v4 = .{mesh_up, mesh_back, mesh_right};
                    
                        color = .{52, 235, 143} / .{255, 255, 255};;
                        
                    // Top
                    } else if face == 4 {
                        v1 = .{mesh_front, mesh_left, mesh_up};
                        v2 = .{mesh_back, mesh_left, mesh_up};
                        v3 = .{mesh_back, mesh_right, mesh_up};
                        v4 = .{mesh_front, mesh_right, mesh_up};
                    
                        color = .{52, 110, 235} / .{255, 255, 255};; 
                        
                    // Bottom
                    } else if face == 5 {
                        v1 = .{mesh_back, mesh_left, mesh_up};
                        v2 = .{mesh_front, mesh_left, mesh_up};
                        v3 = .{mesh_front, mesh_right, mesh_up};
                        v4 = .{mesh_back, mesh_right, mesh_up};
                        
                        color = .{52, 110, 235} / .{255, 255, 255};;
                    }
                    
                    vert1 = .{v1 * VOXEL_SCALE, color};
                    vert2 = .{v2 * VOXEL_SCALE, color};
                    vert3 = .{v3 * VOXEL_SCALE, color};
                    vert4 = .{v4 * VOXEL_SCALE, color};
                    
                    start : u32 = xx vertices.count;
                    
                    array_add(*vertices, vert1);
                    array_add(*vertices, vert2);
                    array_add(*vertices, vert3);
                    array_add(*vertices, vert4);
                    
                    array_add(*indices, 1 + start);
                    array_add(*indices, 2 + start);
                    array_add(*indices, 0 + start);
                    
                    array_add(*indices, 2 + start);
                    array_add(*indices, 3 + start);
                    array_add(*indices, 0 + start);
                }
            }
        }
    }
    
    return create_model(vertices, indices);
}