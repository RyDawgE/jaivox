VoxelChunkOperation :: struct {
    coordinate : Vector3;
    lod : u8 = 1; 
}

VoxelWorld :: struct @entity {
    using #as entity : Entity;
    
    chunks      : [..] u64;
    operations  : [..] VoxelChunkOperation;
}

init_voxel_world :: (world : *VoxelWorld) {
    subscribe_entity_to_tick(world, xx tick_voxel_world);
}

create_voxel_world :: (world : *VoxelWorld) {
    init_voxel_world(world);
    // num of chunks = rd ^ 2
    rd : float : RENDER_DISTANCE;
    lod_intensity : float = 5;
    
    for x : 1.. cast (int) rd {
        for z : 1.. cast (int) rd {

            x_pos : float = x - (rd/2);
            z_pos : float = z - (rd/2);
            
            operation : VoxelChunkOperation = .{};
            operation.coordinate = .{x_pos, 0, z_pos};
            
            dist : float = distance(operation.coordinate, .{0, 0, 0});
            operation.lod = cast (u8) 1 << cast (int) clamp(pow(dist/12, .75), 0, 4);  

            queue_chunk_operation(world, operation);
        }
    }

    // operation : VoxelChunkOperation = .{};
    // operation.coordinate = .{0, 0, 0};
    
    // dist : float = distance(operation.coordinate, .{0, 0, 0});
    // operation.lod = cast (u8) 1 << cast (int) clamp(pow(dist/12, .75), 0, 4);  

    // queue_chunk_operation(world, operation);
}

tick_voxel_world :: (world : *VoxelWorld) {
    using world;
    
    operation_budget : float = .002;
    while operation_budget > 0 {
        if operations.count > 0 {
    		operation_start : Apollo_Time = current_time_monotonic ();    		
            operation : VoxelChunkOperation = operations[0];

            chunk : *VoxelChunk = create_entity(VoxelChunk);            
            init_voxel_chunk(chunk, operation.coordinate, operation.lod);
        
            array_add(*chunks, chunk.id);
            array_unordered_remove_by_index(*operations, 0);
    		
    		operation_end : Apollo_Time = current_time_monotonic ();
    		time : float = cast (float) to_float64_seconds (operation_end - operation_start);            
            operation_budget -= time;        
        }
        else {
            break;
        }
    }
}
queue_chunk_operation :: (world : *VoxelWorld, operation : VoxelChunkOperation) {
    using world;
    
    for op : operations {
        if it_index + 1 >= operations.count {
            array_add(*operations, operation);
            return;
        }
        
        if operations[it_index + 1].lod < operation.lod {
            array_insert_at(*operations, operation, it_index);
            return;
        }
    }
    
    array_add(*operations, operation);
}


