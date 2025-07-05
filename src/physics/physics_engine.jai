PhysicsHandle :: struct {
    physics_system          : *JPH_PhysicsSystem            = null;
    activation_listener     : *JPH_BodyActivationListener   = null;
    contact_listener        : *JPH_ContactListener          = null;
    body_interface          : *JPH_BodyInterface            = null;
    job_system              : *JPH_JobSystem                = null;
    //temp_allocator          : *JPH_TempAllocator            = null;

    global_gravity          : JPH_Vec3                      = .{0, 0, 0};
}

EntityCollider :: struct {
    layer           : ObjectLayer       = .NON_MOVING;
    shape           : JPH_ShapeType     = .Convex;
    physics_body    : *JPH_Body         = null;
}

ObjectLayer :: enum s32 {
    MOVING      :: 0;
    NON_MOVING  :: 1;
    COUNT       :: 2;
}

VEC3_ZERO : Vector3 : .{0, 0, 0};
QUAT_ZERO : Quaternion : .{0, 0, 0, 0};

initialize_physics :: () {
    using game_state.physics_handle;

    if !JPH_Init() then return;
    print("Physics initialized");

    job_system = JPH_JobSystemThreadPool_Create(null);

    //@TODO These are heap allocations! Free them. When? Not sure. Find out!
    broad_phase_layer_interface : *JPH_BroadPhaseLayerInterface          = JPH_BroadPhaseLayerInterfaceMask_Create(1);
    object_vs_broadphase_filter : *JPH_ObjectVsBroadPhaseLayerFilter     = JPH_ObjectVsBroadPhaseLayerFilterMask_Create(broad_phase_layer_interface);
    object_vs_object_filter     : *JPH_ObjectLayerPairFilter             = JPH_ObjectLayerPairFilterMask_Create();

    physics_system_settings : JPH_PhysicsSystemSettings = .{};
    {
        using physics_system_settings;

        maxBodies               = 65536;
        numBodyMutexes          = 0;
        maxBodyPairs            = 1024;
        maxContactConstraints   = 1024;

        broadPhaseLayerInterface        = broad_phase_layer_interface;
        objectLayerPairFilter           = object_vs_object_filter;
        objectVsBroadPhaseLayerFilter   = object_vs_broadphase_filter;
    }

    physics_system = JPH_PhysicsSystem_Create(*physics_system_settings);
    JPH_PhysicsSystem_SetGravity(physics_system, *global_gravity);

    activation_procs : JPH_BodyActivationListener_Procs = .{
        on_body_activated,
        on_body_deactivated
    };

    contact_procs : JPH_ContactListener_Procs = .{
        on_contact_validated,
        on_contact_added,
        on_contact_persisted,
        on_contact_removed
    };

    activation_listener = JPH_BodyActivationListener_Create(activation_procs, null);
    contact_listener    = JPH_ContactListener_Create(contact_procs, null);

    body_interface = JPH_PhysicsSystem_GetBodyInterface(physics_system);
}



create_physics_body :: (entity : *Entity) { // alias for u32
    using game_state.physics_handle;

    // yaw   : Quaternion;
    // pitch : Quaternion;
    // roll  : Quaternion;
    // rotation : Quaternion;

    // set_from_axis_and_angle(*yaw, 0, 0, -1, radians(entity.rotation.x));
    // set_from_axis_and_angle(*pitch, -1, 0, 0, radians(entity.rotation.y));
    // set_from_axis_and_angle(*roll, 0, -1, 0, radians(entity.rotation.z));
    // rotation = yaw * pitch * roll;

    // body_settings : *JPH_BodyCreationSettings = JPH_BodyCreationSettings_Create3(xx JPH_SphereShape_Create(2), xx *entity.position, xx *rotation, .Dynamic, 0);
    // JPH_BodyInterface_CreateAndAddBody(body_interface, body_settings, .Activate);
}

simulate_physics :: () {
    using game_state.physics_handle;

}

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

#scope_file
#import "Jolt";
#load "physics_listener_callbacks.jai";
