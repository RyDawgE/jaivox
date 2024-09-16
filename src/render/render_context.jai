ENABLE_VALIDATION_LAYERS : bool = true;

RenderHandle :: struct {
    window            : *void            =               null;
    instance          : VkInstance       =               null;
    physical_device   : VkPhysicalDevice =     VK_NULL_HANDLE;
    required_validation_layers :: (*u8).["VK_LAYER_KHRONOS_validation"];
    // @ToDo: big stinky hack! fix!!
}

WindowCreationInfo :: struct {
    width  : s32    :      640;
    height : s32    :      480;
    title  : string : "Jaivox";
}

create_game_window :: () {
    window_width  : s32    : WindowCreationInfo.width;
    window_height : s32    : WindowCreationInfo.height;
    window_title  : string : WindowCreationInfo.title;

    game_state.render_handle.window = create_window(window_width, window_height,
                                                    window_title, wanted_msaa = 0);

    return;
}

initialize_render :: (render_handle : *RenderHandle) {
    create_game_window();     // Create Game Window
    create_vulkan_instance(); // Create Vulkan API Instance
    pick_physical_device();   // Select GPU for rendering
}

create_vulkan_instance :: () {
    validation_layers_valid : bool = ENABLE_VALIDATION_LAYERS && check_validation_layer_support() ;
    
    assert(validation_layers_valid);
    
    result : VkResult = .ERROR_INITIALIZATION_FAILED;
    
    extensions := load_platform_extensions(); // This is a platform-specific call.
    
    // Application Info
    app_info : VkApplicationInfo;
    app_info.sType              = .APPLICATION_INFO;
    app_info.pApplicationName   = WindowCreationInfo.title;
    app_info.applicationVersion = VK_MAKE_VERSION(1, 0, 0);
    app_info.pEngineName        = "No Engine";
    app_info.engineVersion      = VK_MAKE_VERSION(1, 0, 0);
    app_info.apiVersion         = VK_API_VERSION_1_0;
    
    // Create Vulkan Instance
    create_info : VkInstanceCreateInfo;
    create_info.sType                   = .INSTANCE_CREATE_INFO;
    create_info.pApplicationInfo        = *app_info;
    create_info.enabledExtensionCount   = cast (u32) extensions.count;
    create_info.ppEnabledExtensionNames = extensions.data;
    
    if (ENABLE_VALIDATION_LAYERS) {
        create_info.enabledLayerCount   = game_state.render_handle.required_validation_layers.count;
        create_info.ppEnabledLayerNames = game_state.render_handle.required_validation_layers.data;
    } else {
        create_info.enabledLayerCount   = 0;
    }
    
    result = vkCreateInstance(*create_info, null, *game_state.render_handle.instance);
    
    assert(result == .VK_SUCCESS);
    
    return;
}

cleanup_vulkan_instance :: () {
    vkDestroyInstance(game_state.render_handle.instance, null);
}

//This function merely makes sure all of the required validation layers are supported on the device.
check_validation_layer_support :: () -> bool {
    available_layers : [..] VkLayerProperties;
    layer_count : u32 = 0;
    
    vkEnumerateInstanceLayerProperties(*layer_count, null);
    
    array_resize(*available_layers, layer_count);
    
    vkEnumerateInstanceLayerProperties(*layer_count, available_layers.data);
    
    assert(available_layers.count != 0);
    
    for layer : game_state.render_handle.required_validation_layers {
        found : bool = false;
        
        for layer_properties : available_layers {
            layer_property_name := cast(string) layer_properties.layerName;
            layer_name_string := to_string(layer);
            layer_property_name.count = layer_name_string.count;
            
            //print("comparing: % to %\n", layer_name_string, layer_property_name);
            if compare(layer_name_string, layer_property_name) == 0 {
                found = true;
                break;
            }
        }
        
        if (!found) {
            return false;
        }
    }
    
    return true;
}

pick_physical_device :: () {
    devices : [..] VkPhysicalDevice; 
    device_count : u32 = 0;

    instance := game_state.render_handle.instance;
    vkEnumeratePhysicalDevices(instance, *device_count, null);
    
    array_resize(*devices, device_count);
    
    vkEnumeratePhysicalDevices(instance, *device_count, devices.data);
    
    assert(devices.count != 0);

}

#scope_file
#import "Vulkan";
#import "Window_Creation";