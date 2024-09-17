ENABLE_VALIDATION_LAYERS : bool : #ifx DEBUG then true else false;

// These are only "Required" By the programmers and will not be considered for release builds.
REQUIRED_VALIDATION_LAYERS :: (*u8).["VK_LAYER_KHRONOS_validation"];

RenderHandle :: struct {
    window            : *void                       =               null;
    instance          : VkInstance                  =               null;
    debug_messenger   : VkDebugUtilsMessengerEXT    =               null;
    physical_device   : VkPhysicalDevice            =     VK_NULL_HANDLE;
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
    setup_debug_messenger();  // Create Vulkan Debug Messenger
    pick_physical_device();   // Select GPU for rendering
}

// Proxy Functions. These get real values in setup_debug_messenger()
CreateDebugUtilsMessengerEXT  : PFN_vkCreateDebugUtilsMessengerEXT;
DestroyDebugUtilsMessengerEXT  : PFN_vkDestroyDebugUtilsMessengerEXT;

create_vulkan_instance :: () {
    result : VkResult = .ERROR_INITIALIZATION_FAILED;
<<<<<<< Updated upstream

    validation_layers_valid : bool = ENABLE_VALIDATION_LAYERS && check_validation_layer_support() ;
    assert(validation_layers_valid, "Not all required validation layers were available.");

    extensions_valid := check_required_extension_support();
    assert(extensions_valid, "Not all required extensions were found");

=======
    
    if (ENABLE_VALIDATION_LAYERS) {
        validation_layers_valid : bool = check_validation_layer_support() ;
        assert(validation_layers_valid, "Not all required validation layers were available.");  
    }
    
    extensions_valid := check_required_extension_support();
    assert(extensions_valid, "Not all required extensions were found");
    
    // @PLATFORM_CALL
>>>>>>> Stashed changes
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
        create_info.enabledLayerCount   = REQUIRED_VALIDATION_LAYERS.count;
        create_info.ppEnabledLayerNames = REQUIRED_VALIDATION_LAYERS.data;
    } else {
        create_info.enabledLayerCount   = 0;
    }

    result = vkCreateInstance(*create_info, null, *game_state.render_handle.instance);

    assert(result == .VK_SUCCESS);
<<<<<<< Updated upstream

    CreateDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(game_state.render_handle.instance, "vkCreateDebugUtilsMessengerEXT");
    DestroyDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(game_state.render_handle.instance, "vkDestroyDebugUtilsMessengerEXT");

=======
    
    if (ENABLE_VALIDATION_LAYERS) {
        CreateDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(game_state.render_handle.instance, "vkCreateDebugUtilsMessengerEXT");
        DestroyDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(game_state.render_handle.instance, "vkDestroyDebugUtilsMessengerEXT");
    }
    
>>>>>>> Stashed changes
    return;
}

cleanup_vulkan_instance :: () {
    if ENABLE_VALIDATION_LAYERS {
        DestroyDebugUtilsMessengerEXT(game_state.render_handle.instance, game_state.render_handle.debug_messenger, null);
    }

    vkDestroyInstance(game_state.render_handle.instance, null);
}


debug_callback :: (severity : VkDebugUtilsMessageSeverityFlagBitsEXT, type : VkDebugUtilsMessageTypeFlagBitsEXT, data : *VkDebugUtilsMessengerCallbackDataEXT, user_data : *void) -> (u32) #c_call {
    new_context: Context;
    push_context new_context {
        print("VULKAN VALIDATION: %\n", to_string(data.pMessage));
    }

    return VK_FALSE;
}

get_available_vulkan_extensions :: () -> [] VkExtensionProperties {
    extension_count: u32;
    extension_array : [] VkExtensionProperties;
    
    vkEnumerateInstanceExtensionProperties(null, *extension_count, null);
    
    assert(extension_count != 0);
    
    array_resize(*extension_array, extension_count);
    
    vkEnumerateInstanceExtensionProperties(null, *extension_count, extension_array.data);

    return extension_array;
}

//This function makes sure the user defined, platform specific required extensions are supported by your hardware vendor.
check_required_extension_support :: () -> bool {
    extensions := load_platform_extensions();
    for required_extension : extensions {
        found : bool = false;
        required_extension_name : string = to_string(required_extension);

        for available_extension : get_available_vulkan_extensions() {
            available_extension_name : string = cast (string) available_extension.extensionName;
            available_extension_name.count = required_extension_name.count;

            //print("comparing: % to %\n", required_extension_name, available_extension_name);

            if compare(required_extension_name, available_extension_name) == 0 {
                //print("Found extension %\n", required_extension_name);
                found = true;
                break;
            }
        }

        if !found {
            assert(false, "Could not find extension %\n", required_extension_name);
            return false;
        }
    };
    return true;
}

//This function merely makes sure all of the required validation layers are supported on the device.
check_validation_layer_support :: () -> bool {
    available_layers : [..] VkLayerProperties;
    layer_count : u32 = 0;

    vkEnumerateInstanceLayerProperties(*layer_count, null);

    array_resize(*available_layers, layer_count);

    vkEnumerateInstanceLayerProperties(*layer_count, available_layers.data);

    assert(available_layers.count != 0);

    for layer : REQUIRED_VALIDATION_LAYERS {
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

setup_debug_messenger :: () {
    if !ENABLE_VALIDATION_LAYERS then return;

    instance := game_state.render_handle.instance;

    // stole this shit from the vulkan example lmao
    if CreateDebugUtilsMessengerEXT {

        debug_callback_create_info: VkDebugUtilsMessengerCreateInfoEXT;
        debug_callback_create_info.sType = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
        debug_callback_create_info.messageSeverity = .VERBOSE_BIT_EXT | .WARNING_BIT_EXT | .ERROR_BIT_EXT;
        debug_callback_create_info.messageType = .GENERAL_BIT_EXT | .VALIDATION_BIT_EXT | .PERFORMANCE_BIT_EXT;
        debug_callback_create_info.pfnUserCallback = debug_callback;

        CreateDebugUtilsMessengerEXT(instance, *debug_callback_create_info, null, *game_state.render_handle.debug_messenger);
    }
}

<<<<<<< Updated upstream
pick_physical_device :: () {
    devices : [..] VkPhysicalDevice;
    device_count : u32 = 0;
=======
generate_physical_device_score :: (device : VkPhysicalDevice) -> int {
    score := 1;
    
    device_properties : VkPhysicalDeviceProperties;
    device_features : VkPhysicalDeviceFeatures;
    
    vkGetPhysicalDeviceProperties(device, *device_properties);
    vkGetPhysicalDeviceFeatures(device, *device_features);
    
    if device_properties.deviceType == {
        case .DISCRETE_GPU;
            score += 1000;
            #through;
>>>>>>> Stashed changes

        case .INTEGRATED_GPU;
            score += 500;
            #through;
            
        case; score += 0;
    }
    
    return score;
}

pick_physical_device :: () {
    devices      : [..] VkPhysicalDevice; 
    device_count :               u32 = 0;
    max_score    :               int = 0;
    
    physical_device : VkPhysicalDevice = VK_NULL_HANDLE;
    instance := game_state.render_handle.instance;
    
    vkEnumeratePhysicalDevices(instance, *device_count, null);

    array_resize(*devices, device_count);

    vkEnumeratePhysicalDevices(instance, *device_count, devices.data);
<<<<<<< Updated upstream

    assert(devices.count != 0);
=======
    
    for device : devices {
        score := generate_physical_device_score(device);
        if (score > max_score) {
            physical_device = device;
            max_score = score;
        }
    }
    
    assert(physical_device != VK_NULL_HANDLE, "No GPU with Vulkan support was found.");
    
    game_state.render_handle.physical_device = physical_device;
    
>>>>>>> Stashed changes
}

#scope_file
#import "Vulkan";
#import "Window_Creation";
