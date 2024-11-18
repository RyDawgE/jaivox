VoxelChunkOperation :: struct {
    coordinate : Vector3;
}


VoxelWorld :: struct @entity {
    using #as entity : Entity;
    
    chunks : [..] u64;
    operations : [..] VoxelChunkOperation;
}

queue_chunk_operation :: (world : *VoxelWorld, operation : VoxelChunkOperation) {
    using world;
    
    array_add(*operations, operation);
}

tick_voxel_world :: (world : *VoxelWorld) {
    using world;
    
    operation_budget : float = .004;
    while operation_budget > 0 {
        if operations.count > 0 {
        
    		operation_start : Apollo_Time = current_time_monotonic ();


            operation : VoxelChunkOperation = operations[0];
            
            chunk : *VoxelChunk = create_entity(VoxelChunk);
            lod : int = xx (distance(operation.coordinate, .{0, 0, 0}) / 4);  
            create_voxel_chunk(chunk, operation.coordinate, lod);
            chunk.position = .{xx (operation.coordinate.x * CHUNK_SIZE * VOXEL_SIZE), 0, xx (operation.coordinate.z * CHUNK_SIZE * VOXEL_SIZE)}; 
        
            array_add(*chunks, chunk.id);
            array_unordered_remove_by_index(*operations, 0);
    		
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

