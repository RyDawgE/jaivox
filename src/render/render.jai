Vertex :: struct {
    position : Vector2;
    color    : Vector3;
}

UniformBufferObject :: struct {
    model : Matrix4;
    view  : Matrix4;
    proj  : Matrix4;
}

Camera :: struct {
    view : Matrix4;
    proj : Matrix4;
}

Model :: struct {
    vertices : [..] Vertex;
    indices  : [..] u16;
}

VERTS : [..] Vertex = xx Vertex.[
    .{.{-.5, -.5}, .{1, 0, 0}},
    .{.{ .5, -.5}, .{0, 1, 0}},
    .{.{ .5,  .5}, .{0, 0, 1}},
    .{.{-.5,  .5}, .{1, 1, 1}},
];

INDICES : [..] u16 = xx u16.[
    0, 1, 2, 2, 3, 0,
];



