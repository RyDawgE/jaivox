Vertex :: struct {
    position : Vector2;
    color    : Vector3;
}

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
