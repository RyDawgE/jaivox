SCENE_PROCEDURE_SIGNATURE :: #type (scene : *Scene);

Scene :: struct {
    entry_procedure : SCENE_PROCEDURE_SIGNATURE = default_entry;

    entity_handle  : *EntityHandle;

    background : TextureData;
//  background_transition : something
};

cleanup_scene :: (scene : *Scene) {
    if scene.entity_handle then cleanup_entity_handle(scene.entity_handle);
    free(scene);
}

default_entry :: (scene : *Scene) {
    print("No scene entry :(\n");
    return;
}