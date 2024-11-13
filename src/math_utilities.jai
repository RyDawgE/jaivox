// math util

radians :: (degrees : float) -> float {
    return degrees * (PI / 180);
}

look_at_rotation :: (start : Vector3, target : Vector3) -> Vector3 {
    return .{0,0,0};
}

get_forward_vector :: (rotation : Vector3) -> Vector3 {
    // yaw, pitch, roll
    // x, y, z
    forward : Vector3 = .{0,0,0};
    
    yaw := radians(rotation.x);
    pitch := radians(rotation.y);
    
    forward.x = cos(pitch) * sin(yaw);
    forward.y = -sin(pitch) * cos(yaw);
    forward.z = -(cos(pitch));
    
    return forward;
}

get_right_vector :: (rotation : Vector3) -> Vector3 {
    right   : Vector3 = .{0, 0, 0};
    
    yaw := radians(rotation.x);
    pitch := radians(rotation.y);
    
    right.x = cos(yaw);
    right.y = -sin(yaw);
    right.z = 0;
    
    return right;

}