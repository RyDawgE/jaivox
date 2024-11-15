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
    yaw   : Quaternion;
    pitch : Quaternion;

    set_from_axis_and_angle(*yaw, 0, -1, 0, radians(rotation.x));
    set_from_axis_and_angle(*pitch, -1, 0, 0, radians(rotation.y));
    
    rotation_quat : Quaternion = yaw * pitch;
    
    inverted : Matrix4 = inverse(rotation_matrix(Matrix4, rotation_quat));
    
    forward = normalize(Vector3.{inverted.coef[2][0], inverted.coef[2][1], inverted.coef[2][2]});
        
    return forward;
}

get_right_vector :: (rotation : Vector3) -> Vector3 {
    // yaw, pitch, roll
    // x, y, z 
    right   : Vector3 = .{0, 0, 0};
    
    right = cross(get_forward_vector(rotation), .{0, 1, 0});
    
    
    return right;

}