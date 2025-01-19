DebugEntity :: struct @entity {
    using #as entity : Entity;
}

init_debug_entity :: (entity : *DebugEntity) {
    subscribe_entity_to_tick(entity, xx tick_debug_entity);
        
    entity.model = create_model(
        SAMPLE_VERTS,
        SAMPLE_INDXS
    );
}

tick_debug_entity :: (entity : *DebugEntity) {
    entity.rotation.z += (10 * game_state.delta_time);
}
