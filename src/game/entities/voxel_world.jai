VoxelChunkOperation :: struct {
    coordinate : Vector3;
    lod : int = 1; 
}


VoxelWorld :: struct @entity {
    using #as entity : Entity;
    
    chunks : [..] u64;
    operations : [..] VoxelChunkOperation;
}

create_voxel_world :: (world : *VoxelWorld) {
    init_voxel_world(world);
    // num of chunks = rd ^ 2
    rd := 176;
    lod_intensity : float = 6;
    
    for x : 1..rd {
        for z : 1..rd {

            x_pos := x - (rd/2);
            z_pos := z - (rd/2);
        
            operation : VoxelChunkOperation = .{};
            operation.coordinate = .{xx x_pos, 0, xx z_pos};
            operation.lod = xx (distance(operation.coordinate, .{0, 0, 0}) / lod_intensity);  

            
            queue_chunk_operation(world, operation);
        }
    }
}

init_voxel_world :: (world : *VoxelWorld) {
    subscribe_entity_to_tick(world, xx tick_voxel_world);
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

tick_voxel_world :: (world : *VoxelWorld) {
    using world;
    
    operation_budget : float = .002;
    while operation_budget > 0 {
        if operations.count > 0 {
        
    		operation_start : Apollo_Time = current_time_monotonic ();

            operation : VoxelChunkOperation = operations[0];
            
            chunk : *VoxelChunk = create_entity(VoxelChunk);

            create_voxel_chunk_data(chunk, operation.coordinate, operation.lod);

            chunk.position = .{xx (operation.coordinate.x * CHUNK_SIZE * VOXEL_SIZE), 0, xx (operation.coordinate.z * CHUNK_SIZE * VOXEL_SIZE)}; 
        
            create_voxel_model(game_state.render_handle.voxel_render_data, chunk.id);
        
            array_add(*chunks, chunk.id);
            array_unordered_remove_by_index(*operations, 0);
    		
    		free(model);
    		
    		operation_end : Apollo_Time = current_time_monotonic ();
    		
    		time : float = cast (float) to_float64_seconds (operation_end - operation_start);
            
    		//print("%\n", time);
            
            operation_budget -= time;        
        }
        else {
            break;
        }
    }
}

