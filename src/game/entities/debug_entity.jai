DebugEntity :: struct @entity {
    using #as entity : Entity;
}

init_debug_entity :: (entity : *DebugEntity) {
    subscribe_entity_to_tick(entity, xx tick_debug_entity);
    subscribe_entity_to_render(entity);
        
    cube_verts, cube_indices := create_debug_cube_mesh();
        
    entity.model = create_model(
        cube_verts,
        cube_indices
    );
}

tick_debug_entity :: (entity : *DebugEntity) {
    entity.rotation.z += (10 * game_state.delta_time);
}

create_debug_cube_mesh :: () -> [..] Vertex, [..] u32 {
     cube_verts : [..] Vertex = resizable ( Vertex.[
        .{.{-1,  -1, 1}, .{0, 0, 1}, .{0, 1}},
        .{.{1, -1, 1},   .{0, 0, 1}, .{0, 1}},
        .{.{-1, 1, 1},   .{1, 0, 0}, .{0, 0}},
        .{.{1, 1, 1},    .{1, 0, 0}, .{0, 0}},
        
        .{.{-1,  -1, -1}, .{0, 0, 1}, .{0, 1}},
        .{.{1, -1, -1},   .{0, 0, 1}, .{0, 1}},
        .{.{-1, 1, -1},   .{1, 0, 0}, .{0, 0}},
        .{.{1, 1, -1},    .{1, 0, 0}, .{0, 0}},
    ] );
        
    cube_indices : [..] u32 = resizable ( u32.[
        //Top
        7, 6, 2,
        2, 3, 7,

        //Bottom
        0, 4, 5,
        5, 1, 0,

        //Left
        0, 2, 6,
        6, 4, 0,

        //Right
        7, 3, 1,
        1, 5, 7,

        //Front
        3, 2, 0,
        0, 1, 3,

        //Back
        4, 6, 7,
        7, 5, 4
    ] );
    
    return cube_verts, cube_indices;
}
