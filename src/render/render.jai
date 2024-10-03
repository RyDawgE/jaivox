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
    .{.{-.5,  .5}, .{1, 1, 1}}
];

INDICES : [..] u16 = xx u16.[
    0, 1, 2, 2, 3, 0
];

get_binding_description :: ($T : Type) -> VkVertexInputBindingDescription {
    binding_description : VkVertexInputBindingDescription = .{};
    {
        using binding_description;
        
        binding = 0;
        stride  = size_of(T);
        inputRate = .VERTEX;
    }
    
    return binding_description;
}

get_attribute_descriptions :: ($T : Type) -> [2] VkVertexInputAttributeDescription {
    attribute_descriptions : [2] VkVertexInputAttributeDescription;
    {
        using attribute_descriptions[0];
        
        binding  = 0;
        location = 0;
        format   = .R32G32_SFLOAT;
        offset   = #run offset_of(Vertex, "position");
    }
    
    {
        using attribute_descriptions[1];
        
        binding  = 0;
        location = 1;
        format   = .R32G32B32_SFLOAT;
        offset   = #run offset_of(Vertex, "color");
    }
    
    return attribute_descriptions;
}

