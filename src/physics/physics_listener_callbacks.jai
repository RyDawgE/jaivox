//@TODO: move these to another file probably idfk.
on_body_activated :: (userData: *void, bodyID: JPH_BodyID, bodyUserData: u64) -> void #c_call {
    push_context {
        print("Body Activated!\n");
    } 
}

//@TODO: move these to another file probably idfk.
on_body_deactivated :: (userData: *void, bodyID: JPH_BodyID, bodyUserData: u64) -> void #c_call {
    push_context {
        print("Body Deactivated");
    }
}


on_contact_validated :: (userData: *void, body1: *JPH_Body, body2: *JPH_Body, baseOffset: *JPH_RVec3, collisionResult: *JPH_CollideShapeResult) -> JPH_ValidateResult #c_call {
    return 1; 
}

on_contact_added :: (userData: *void, body1: *JPH_Body, body2: *JPH_Body, manifold: *JPH_ContactManifold, settings: *JPH_ContactSettings) -> void #c_call {

}

on_contact_persisted :: (userData: *void, body1: *JPH_Body, body2: *JPH_Body, manifold: *JPH_ContactManifold, settings: *JPH_ContactSettings) -> void #c_call {

}

on_contact_removed :: (userData: *void, subShapePair: *JPH_SubShapeIDPair) -> void #c_call {

}
