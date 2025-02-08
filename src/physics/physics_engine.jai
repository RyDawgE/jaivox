PhysicsHandle :: struct {
    physics_system      : *JPH_PhysicsSystem            = null;
    activation_listener : *JPH_BodyActivationListener   = null; 
    contact_listener    : *JPH_ContactListener          = null;
    body_interface      : *JPH_BodyInterface            = null;
}

EntityCollider :: struct {
    shape           : JPH_ShapeType     = .Convex;
    subshape        : JPH_ShapeSubType  = .Box;
    physics_body    : *JPH_Body         = null;
}

initialize_physics :: () {
    create_jolt_physics_system();
    create_interaction_listeners();
    set_body_interface();
}

create_jolt_physics_system :: () {
    using game_state.physics_handle;
    
    JPH_Init();
    
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
}

create_interaction_listeners :: () {
    using game_state.physics_handle;
    
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
}

set_body_interface :: () {
    using game_state.physics_handle;
     
    body_interface = JPH_PhysicsSystem_GetBodyInterface(physics_system);
}

create_physics_body :: (entity : *Entity) { // alias for u32
    using game_state.physics_handle;
    
    yaw   : Quaternion;
    pitch : Quaternion;
    roll  : Quaternion; 
    rotation : Quaternion;    
    
    set_from_axis_and_angle(*yaw, 0, 0, -1, radians(entity.rotation.x));
    set_from_axis_and_angle(*pitch, -1, 0, 0, radians(entity.rotation.y));
    set_from_axis_and_angle(*roll, 0, -1, 0, radians(entity.rotation.z));
    rotation = yaw * pitch * roll;

    body_settings : *JPH_BodyCreationSettings = JPH_BodyCreationSettings_Create3(xx JPH_SphereShape_Create(2), xx *entity.position, xx *rotation, .Dynamic, 0);
    JPH_BodyInterface_CreateAndAddBody(body_interface, body_settings, .Activate);
}

simulate_physics :: () {
    using game_state.physics_handle;
    
}

#scope_file
#import "Jolt";
#load "physics_listener_callbacks.jai";