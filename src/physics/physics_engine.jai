PhysicsHandle :: struct {
    physics_system      : *JPH_PhysicsSystem = null;
    activation_listener : *JPH_BodyActivationListener = null; 
}

initialize_physics :: () {
    create_jolt_physics_system();
    create_interaction_listeners();
}

create_jolt_physics_system :: () {
    using game_state.physics_handle;
    
    JPH_Init();
    
    broad_phase_layer_interface : *JPH_BroadPhaseLayerInterface          = JPH_BroadPhaseLayerInterfaceMask_Create(1);
    object_vs_broadphase_filter : *JPH_ObjectVsBroadPhaseLayerFilter     = JPH_ObjectVsBroadPhaseLayerFilterMask_Create(broad_phase_layer_interface);
    object_vs_object_filter     : *JPH_ObjectLayerPairFilter             = JPH_ObjectLayerPairFilterMask_Create();
    
    physics_system_settings : *JPH_PhysicsSystemSettings = New(JPH_PhysicsSystemSettings);
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

    physics_system = JPH_PhysicsSystem_Create(physics_system_settings);        
}

create_interaction_listeners :: () {
    using game_state.physics_handle;
    
    activation_procs : JPH_BodyActivationListener_Procs = .{
        on_body_activated,
        on_body_deactivated
    };

    activation_listener = JPH_BodyActivationListener_Create(activation_procs, null);

    contact_procs : JPH_ContactListener_Procs = .{
    
    
    };
}

simulate_physics :: () {
    using game_state.physics_handle;
    
}

#scope_file
#import "Jolt";
#load "physics_listener_callbacks.jai";