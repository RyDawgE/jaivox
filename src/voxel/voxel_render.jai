// voxel render

VoxelModel :: struct {
    texture_object : u32 = 0;
    base_vertex    : u32 = 0;
    vertex_count   : u32 = 0; 
    base_element   : u32 = 0; 
    element_count  : u32 = 0;
}

VoxelWorldRenderData :: struct {
    vertex_buffer      : [..] Vertex;
    index_buffer       : [..] u32;
    chunk_entity_ids   : [..] u64;
    VAO : u32;
    VBO : u32;
    EBO : u32;
    //TODO: Make this a table or something
    texture : u32;
}


binary_greedy_mesh :: (world_render : *VoxelWorldRenderData, chunk : *VoxelChunkData) -> *VoxelModel {
    using chunk;
    
    model : *VoxelModel = New(VoxelModel);
    
    start : u32 = xx world_render.vertex_buffer.count;
    indx_start : u32 = xx world_render.index_buffer.count;
    model.base_vertex = start;
    model.base_element = indx_start;
    
    
    cs : u32 = CHUNK_SIZE / cast (u32) chunk.lod;
    vs : float = VOXEL_SIZE * chunk.lod;
    
    cs_p  : u32 = cs + 2;
    cs_p2 : u32 = cs_p * cs_p;
    cs_p3 : u32 = cs_p * cs_p * cs_p;
    
    cs_last_bit : int = cs_p - 1;
    edge_mask   : u64 = (ULL1 << cs_last_bit) + ULL1;
    
    cs_ratio : float = (cs * vs) / CHUNK_WORLD_SCALE;
    
    vertices : [..] Vertex;
    indices  : [..] u32;
    
    array_reserve(*vertices, voxels.count * 4);
    array_reserve(*indices, indices.count * 6);
    
    axis_cols      : [..] u64;
    col_face_masks : [..] u64;
    
    array_resize(*axis_cols, cs_p2 * 3);
    array_resize(*col_face_masks, cs_p2 * 6);
    
    offset : Vector3 = .{vs, vs, vs};

    voxel_index : s32 = 0;
    for y : 0..cs_p - 1 {
        y_offset : int = (y * cs_p) + cs_p2;
        for x : 0..cs_p - 1 {
            zb : u64 = 0;
            for z : 0..cs_p - 1 {
                if (voxels[voxel_index] & 1 == 1) { // if first bit == 1, voxel is occupied
                    axis_cols[x + (z * cs_p)] |= ULL1 << y;
                    axis_cols[z + y_offset] |= ULL1 << x;
                    zb |= ULL1 << z;
                }         
                voxel_index += 1;
            }
            axis_cols[y + (x * cs_p) + (cs_p2 * 2)] = zb;
        }
    }
    
    for axis : 0..2 {
        for i : 0..cs_p2 - 1 {
            col : u64 = axis_cols[(cs_p2 * axis) + i];
            col_face_masks[(cs_p2 * (axis * 2)) + i] = col & ~((col >> 1) | (ULL1 << cs_last_bit));
            col_face_masks[(cs_p2 * (axis * 2 + 1)) + i] = col & ~((col << 1) | ULL1);
        }
    }
    
    
    for face : 0..5 {
        axis : int = face / 2;
        facexCS_P2 : int = face * cs_p2;
        face_even_offset : int = ifx (face % 2 == 0) then 1 else 0; 
        
        merged_forward : [..] int;
        array_resize(*merged_forward, cs_p2 * 6);
        for forward : 1..cs_last_bit - 1 {
            forwardxCS_PxfacexCS_P2 : int = (forward * cs_p) + facexCS_P2;
            bits_walking_right : u64 = 0;
            merged_right : [..] int;
            array_resize(*merged_right, cs_p);

            forwardGteCS : bool = forward >= cs;
            
            for right : 1..cs_last_bit - 1 {
                rightxCS_P : int = right * cs_p;
                
                bits_here : u64 = col_face_masks[right + forwardxCS_PxfacexCS_P2] & ~edge_mask;
                bits_merging_forward : u64 = ifx forwardGteCS then 0 else (bits_here & ~bits_walking_right & col_face_masks[right + forwardxCS_PxfacexCS_P2 + cs_p]);
                
                //print("Merging Forward\n");
                copy_front : u64 = bits_merging_forward;
                while (copy_front) {
                    bit_pos : int = bit_scan_forward(copy_front) - 1; //Could cause problems
                    copy_front &= ~(ULL1 << bit_pos);
                    
                    merged_forward[rightxCS_P + bit_pos] += 1;
                }
                
                bits_merging_right : u64 = ifx right >= cs then 0 else (bits_here & (col_face_masks[right + 1 + forwardxCS_PxfacexCS_P2]));
                
                //print("Merging Right\n");
                bits_stopped_forward : u64 = bits_here & ~bits_merging_forward;
                while (bits_stopped_forward) {
                    //print("%\n", formatInt(bits_stopped_forward, 2));
                    bit_pos : int = bit_scan_forward(bits_stopped_forward) - 1;
                    bits_stopped_forward &= ~(ULL1 << bit_pos);
                    
                    shifted_pos : u64 = ULL1 << bit_pos;
                    if ((bits_merging_right & (shifted_pos)) && merged_forward[rightxCS_P + bit_pos] == merged_forward[(right + 1) * cs_p + bit_pos]) {
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
                    
                    uv1 : Vector2;
                    uv2 : Vector2;
                    uv3 : Vector2;
                    uv4 : Vector2;
                    
                    vert1 : Vertex;
                    vert2 : Vertex;
                    vert3 : Vertex;
                    vert4 : Vertex;
                    
                    color : Vector3;
                    
                    // Up
                    if face == 0 {
                        v1 = .{mesh_left, mesh_up, mesh_front};
                        v2 = .{mesh_left, mesh_up, mesh_back};
                        v3 = .{mesh_right, mesh_up, mesh_back};
                        v4 = .{mesh_right, mesh_up, mesh_front};
                        
                        uv1 = .{(v1.x - 1) / cs, (v1.z - 1) / cs};
                        uv2 = .{(v2.x - 1) / cs, (v2.z - 1) / cs};
                        uv3 = .{(v3.x - 1) / cs, (v3.z - 1) / cs};
                        uv4 = .{(v4.x - 1) / cs, (v4.z - 1) / cs};

                        color = .{52, 235, 143} / .{255, 255, 255};
                        
                    // Down
                    } else if face == 1 {
                        v1 = .{mesh_left, mesh_up, mesh_back};
                        v2 = .{mesh_left, mesh_up, mesh_front};
                        v3 = .{mesh_right, mesh_up, mesh_front};
                        v4 = .{mesh_right, mesh_up, mesh_back}; 
                        
                        uv1 = .{(v1.x - 1) / cs, (v1.z - 1) / cs};
                        uv2 = .{(v2.x - 1) / cs, (v2.z - 1) / cs};
                        uv3 = .{(v3.x - 1) / cs, (v3.z - 1) / cs};
                        uv4 = .{(v4.x - 1) / cs, (v4.z - 1) / cs};
                    
                        color = .{52, 235, 143} / .{255, 255, 255};
    
                    // Right
                    } else if face == 2 {
                        v1 = .{mesh_up, mesh_front, mesh_left};
                        v2 = .{mesh_up, mesh_back, mesh_left};
                        v3 = .{mesh_up, mesh_back, mesh_right};
                        v4 = .{mesh_up, mesh_front, mesh_right};
                        
                        uv1 = .{(v1.y - 1) / cs, (v1.z - 1) / cs};
                        uv2 = .{(v2.y - 1) / cs, (v2.z - 1) / cs};
                        uv3 = .{(v3.y - 1) / cs, (v3.z - 1) / cs};
                        uv4 = .{(v4.y - 1) / cs, (v4.z - 1) / cs};

                        color = .{235, 64, 52} / .{255, 255, 255};
                        
                    // Left
                    } else if face == 3 {
                        v1 = .{mesh_up, mesh_back, mesh_left};
                        v2 = .{mesh_up, mesh_front, mesh_left};
                        v3 = .{mesh_up, mesh_front, mesh_right};
                        v4 = .{mesh_up, mesh_back, mesh_right};

                        uv1 = .{(v1.y - 1) / cs, (v1.z - 1) / cs};
                        uv2 = .{(v2.y - 1) / cs, (v2.z - 1) / cs};
                        uv3 = .{(v3.y - 1) / cs, (v3.z - 1) / cs};
                        uv4 = .{(v4.y - 1) / cs, (v4.z - 1) / cs};
                    
                        color = .{235, 64, 52} / .{255, 255, 255};
                        
                    // Front
                    } else if face == 4 {
                        v1 = .{mesh_front, mesh_left, mesh_up};
                        v2 = .{mesh_back, mesh_left, mesh_up};
                        v3 = .{mesh_back, mesh_right, mesh_up};
                        v4 = .{mesh_front, mesh_right, mesh_up};
                        
                        uv1 = .{(v1.x - 1) / cs, (v1.y - 1) / cs};
                        uv2 = .{(v2.x - 1) / cs, (v2.y - 1) / cs};
                        uv3 = .{(v3.x - 1) / cs, (v3.y - 1) / cs};
                        uv4 = .{(v4.x - 1) / cs, (v4.y - 1) / cs};     
                    
                        color = .{52, 110, 235} / .{255, 255, 255};
                        
                    // Back
                    } else if face == 5 {
                        v1 = .{mesh_back, mesh_left, mesh_up};
                        v2 = .{mesh_front, mesh_left, mesh_up};
                        v3 = .{mesh_front, mesh_right, mesh_up};
                        v4 = .{mesh_back, mesh_right, mesh_up};
                        
                        uv1 = .{(v1.x - 1) / cs, (v1.y - 1) / cs};
                        uv2 = .{(v2.x - 1) / cs, (v2.y - 1) / cs};
                        uv3 = .{(v3.x - 1) / cs, (v3.y - 1) / cs};
                        uv4 = .{(v4.x - 1) / cs, (v4.y - 1) / cs};     
                        
                        color = .{52, 110, 235} / .{255, 255, 255};
                    }
                    
                    vert1 = .{(v1 * (vs / cs_ratio) - offset) + (chunk.location * CHUNK_WORLD_SCALE), color, uv1};
                    vert2 = .{(v2 * (vs / cs_ratio) - offset) + (chunk.location * CHUNK_WORLD_SCALE), color, uv2};
                    vert3 = .{(v3 * (vs / cs_ratio) - offset) + (chunk.location * CHUNK_WORLD_SCALE), color, uv3};
                    vert4 = .{(v4 * (vs / cs_ratio) - offset) + (chunk.location * CHUNK_WORLD_SCALE), color, uv4};
                    
                    start : u32 = xx world_render.vertex_buffer.count;
                    
                    array_add(*world_render.vertex_buffer, vert1);
                    array_add(*world_render.vertex_buffer, vert2);
                    array_add(*world_render.vertex_buffer, vert3);
                    array_add(*world_render.vertex_buffer, vert4);
                    
                    model.vertex_count += 4;
                    model.element_count += 6;
                    
                }
            }
            array_free(merged_right);
        }
        array_free(merged_forward);
    }
    
    return model;
}