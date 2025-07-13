create_voxel_chunk_shape :: (voxel_chunk : *VoxelChunk) -> *JPH_Shape {
    using game_state.render_handle;

    jph_shape : *JPH_Shape;
    compound_shape_settings := JPH_StaticCompoundShapeSettings_Create();
    defer JPH_ShapeSettings_Destroy(xx compound_shape_settings);

    vmodel : *VoxelModel            = voxel_chunk.voxel_model;
    vwrld  : *VoxelWorldRenderData  = voxel_render_data;

    ntris := vmodel.element_count / 3;
    triangles : [..] JPH_Triangle;
    triangles.allocator = temp;
    array_reserve(*triangles, ntris);
    for 0..ntris - 1 {
        v1_index := vwrld.index_buffer[vmodel.base_element + it * 3    ];
        v2_index := vwrld.index_buffer[vmodel.base_element + it * 3 + 1];
        v3_index := vwrld.index_buffer[vmodel.base_element + it * 3 + 2];

        v1       := vwrld.vertex_buffer[vmodel.base_vertex + v1_index].position;
        v2       := vwrld.vertex_buffer[vmodel.base_vertex + v2_index].position;
        v3       := vwrld.vertex_buffer[vmodel.base_vertex + v3_index].position;

        tri      := JPH_Triangle.{
            v1 = .{v1.x, v1.y, v1.z},
            v2 = .{v2.x, v2.y, v2.z},
            v3 = .{v3.x, v3.y, v3.z},
        };

        array_add(*triangles, tri);
    }

    mesh_shape_settings := JPH_MeshShapeSettings_Create(triangles.data, xx triangles.count);
    defer JPH_ShapeSettings_Destroy(xx mesh_shape_settings);
    mesh_shape := JPH_MeshShapeSettings_CreateShape(mesh_shape_settings);
    JPH_CompoundShapeSettings_AddShape2(xx compound_shape_settings, xx *VEC3_ZERO, xx *QUAT_ZERO, cast(*JPH_Shape) mesh_shape, 0);

    jph_shape = xx JPH_StaticCompoundShape_Create(compound_shape_settings);

    return jph_shape;
}