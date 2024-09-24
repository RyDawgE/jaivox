#if DEBUG {
    ENABLE_VALIDATION_LAYERS :: true;
} else {
    ENABLE_VALIDATION_LAYERS :: false;
}

REQUIRED_DEVICE_EXTENSIONS :: (*u8).[VK_KHR_SWAPCHAIN_EXTENSION_NAME];

// These are only "Required" By the programmers and will not be considered for release builds.
REQUIRED_VALIDATION_LAYERS :: (*u8).["VK_LAYER_KHRONOS_validation"];

RenderHandle :: struct {
    window                  : *void                    = null;
    instance                : VkInstance               = null;
    surface                 : VkSurfaceKHR             = VK_NULL_HANDLE;
    debug_messenger         : VkDebugUtilsMessengerEXT = null;
    physical_device         : VkPhysicalDevice         = VK_NULL_HANDLE;
    logical_device          : VkDevice                 = VK_NULL_HANDLE;
    graphics_queue          : VkQueue                  = null;
    present_queue           : VkQueue                  = null;
    swap_chain              : VkSwapchainKHR           = null;
    swap_chain_images       : [..] VkImage;
    swap_chain_image_views  : [..] VkImageView;
    swap_chain_image_format : VkFormat;
    swap_chain_extent       : VkExtent2D;
    render_pass             : VkRenderPass;
    pipeline_layout         : VkPipelineLayout;
    graphics_pipeline       : VkPipeline;
    swap_chain_framebuffers : [..] VkFramebuffer;
}

WindowCreationInfo :: struct {
    width  : s32    :  640;
    height : s32    :  480;
    title  : string : "Jaivox";
}

QueueFamilyIndices :: struct {
    graphics_family       : u32  = 0;
    graphics_family_valid : bool = false;
    present_family        : u32  = 0;
    present_family_valid  : bool = false;
}

SwapChainSupportDetails :: struct {
    capabilities : VkSurfaceCapabilitiesKHR;;
    formats : [..] VkSurfaceFormatKHR;
    present_modes : [..] VkPresentModeKHR;
}

initialize_render :: (render_handle : *RenderHandle) {
    create_game_window();     // Create Game Window
    create_vulkan_instance(); // Create Vulkan API Instance
    setup_debug_messenger();  // Create Vulkan Debug Messenger
    create_surface();         // Create Vulkan Surface to render to Game Window
    pick_physical_device();   // Select GPU for rendering
    create_logical_device();  // Create Vulkan Logic Profile on GPU
    create_swap_chain();      // Create Image Chain Buffer
    create_image_views();     // Create Views for each Image
    create_render_pass();     // Create Render Pass for Pipeline Config
    create_render_pipeline(); // Create Render Pipeline
    create_framebuffers();    // Create Frame Buffers
}

create_game_window :: () {
    window_width  : s32    : WindowCreationInfo.width;
    window_height : s32    : WindowCreationInfo.height;
    window_title  : string : WindowCreationInfo.title;

    game_state.render_handle.window = create_window(window_width, window_height,
                                                    window_title, wanted_msaa = 0);

    return;
}

// Proxy Functions. These get real values in setup_debug_messenger()
CreateDebugUtilsMessengerEXT  : PFN_vkCreateDebugUtilsMessengerEXT;
DestroyDebugUtilsMessengerEXT  : PFN_vkDestroyDebugUtilsMessengerEXT;

create_vulkan_instance :: () {
    result : VkResult = .ERROR_INITIALIZATION_FAILED;

    if (ENABLE_VALIDATION_LAYERS) {
        validation_layers_valid : bool = check_validation_layer_support() ;
        assert(validation_layers_valid, "Not all required validation layers were available.");
    }

    extensions_valid := check_required_instance_extension_support();
    assert(extensions_valid, "Not all required extensions were found");

    // @PLATFORM_CALL
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
    vulkan_instance_create_info : VkInstanceCreateInfo = .{};
    {
        using vulkan_instance_create_info;

        sType                   = .INSTANCE_CREATE_INFO;
        pApplicationInfo        = *app_info;
        enabledExtensionCount   = cast (u32) extensions.count;
        ppEnabledExtensionNames = extensions.data;

        if (ENABLE_VALIDATION_LAYERS) {
            enabledLayerCount   = REQUIRED_VALIDATION_LAYERS.count;
            ppEnabledLayerNames = REQUIRED_VALIDATION_LAYERS.data;
        } else {
            enabledLayerCount   = 0;
        }
    }

    result = vkCreateInstance(*vulkan_instance_create_info, null, *game_state.render_handle.instance);

    assert(result == .VK_SUCCESS);

    if (ENABLE_VALIDATION_LAYERS) {
        CreateDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(game_state.render_handle.instance, "vkCreateDebugUtilsMessengerEXT");
        DestroyDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(game_state.render_handle.instance, "vkDestroyDebugUtilsMessengerEXT");
    }


    return;
}

cleanup_vulkan_instance :: () {
    using game_state.render_handle;
    
    for framebuffer : swap_chain_framebuffers {
        vkDestroyFramebuffer(logical_device, framebuffer, null);
    }
    
    vkDestroyPipeline(logical_device, graphics_pipeline, null);
    vkDestroyPipelineLayout(logical_device, pipeline_layout, null);
    vkDestroyRenderPass(logical_device, render_pass, null);

    for image_view : swap_chain_image_views {
        vkDestroyImageView(logical_device, image_view, null);
    }

    vkDestroySwapchainKHR(logical_device, game_state.render_handle.swap_chain, null);
    vkDestroyDevice(logical_device, null);
    vkDestroySurfaceKHR(instance, surface, null);

    if ENABLE_VALIDATION_LAYERS {
        DestroyDebugUtilsMessengerEXT(instance, debug_messenger, null);
    }

    vkDestroyInstance(instance, null);

}


debug_callback :: (severity : VkDebugUtilsMessageSeverityFlagBitsEXT, type : VkDebugUtilsMessageTypeFlagBitsEXT, data : *VkDebugUtilsMessengerCallbackDataEXT, user_data : *void) -> (u32) #c_call {
    new_context: Context;
    push_context new_context {
        print("VULKAN VALIDATION: %\n", to_string(data.pMessage));
    }

    return VK_FALSE;
}

query_swap_chain_support :: (device : VkPhysicalDevice) -> SwapChainSupportDetails {
    details : SwapChainSupportDetails = .{};

    vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device, game_state.render_handle.surface, *details.capabilities);

    format_count : u32 = 0;
    vkGetPhysicalDeviceSurfaceFormatsKHR(device, game_state.render_handle.surface, *format_count, null);
    if (format_count > 0) {
        array_resize(*details.formats, format_count);
        vkGetPhysicalDeviceSurfaceFormatsKHR(device, game_state.render_handle.surface, *format_count, details.formats.data);
    }

    present_mode_count : u32 = 0;
    vkGetPhysicalDeviceSurfacePresentModesKHR(device, game_state.render_handle.surface, *present_mode_count, null);
    if (present_mode_count > 0) {
        array_resize(*details.present_modes, present_mode_count);
        vkGetPhysicalDeviceSurfacePresentModesKHR(device, game_state.render_handle.surface, *present_mode_count, details.present_modes.data);
    }

    return details;
}

choose_swap_surface_format :: (available_formats : [..] VkSurfaceFormatKHR) -> VkSurfaceFormatKHR {
    for available_format : available_formats {
        if (available_format.format == .B8G8R8A8_SRGB && available_format.colorSpace == .COLOR_SPACE_SRGB_NONLINEAR_KHR) {
            return available_format;
        }
    }

    return available_formats[0];
}

choose_swap_present_mode :: (available_present_modes : [..] VkPresentModeKHR) -> VkPresentModeKHR {
    for available_present_mode : available_present_modes {
        if (available_present_mode == .MAILBOX_KHR) {
            return available_present_mode;
        }
    }

    return .FIFO_KHR;
}

choose_swap_extent :: (capabilities : VkSurfaceCapabilitiesKHR) -> VkExtent2D {
    extent : VkExtent2D;

    if (capabilities.currentExtent.width != U32_MAX) {
        extent = capabilities.currentExtent;
    } else {
        extent.width  = cast (u32) clamp(WindowCreationInfo.width, cast (s32) capabilities.minImageExtent.width, cast (s32) capabilities.maxImageExtent.width);
        extent.height = cast (u32) clamp(WindowCreationInfo.height, cast (s32) capabilities.minImageExtent.height, cast (s32) capabilities.maxImageExtent.height);
    }

    return extent;
}

create_swap_chain :: () {
    using game_state.render_handle;

    swap_chain_support : SwapChainSupportDetails = query_swap_chain_support(physical_device);
    surface_format     : VkSurfaceFormatKHR      = choose_swap_surface_format(swap_chain_support.formats);
    present_mode       : VkPresentModeKHR        = choose_swap_present_mode(swap_chain_support.present_modes);
    extent             : VkExtent2D              = choose_swap_extent(swap_chain_support.capabilities);
    image_count        : u32                     = swap_chain_support.capabilities.minImageCount + 1;

    indices : QueueFamilyIndices = find_queue_families(physical_device);
    unique_queue_families : [..] u32;

    gfx_present_families_same : bool = indices.graphics_family == indices.present_family;

    // @TODO: Clean this up a bit.
    if (gfx_present_families_same) {
        array_add(*unique_queue_families, indices.graphics_family);
    } else {
        array_add(*unique_queue_families, indices.graphics_family);
        array_add(*unique_queue_families, indices.present_family);
    }


    if swap_chain_support.capabilities.maxImageCount > 0 && image_count > swap_chain_support.capabilities.maxImageCount {
        image_count = swap_chain_support.capabilities.maxImageCount;
    }

    swapchain_create_info : VkSwapchainCreateInfoKHR = .{};
    // Thanks for the tip, tsoding!
    {
        using swapchain_create_info;

        sType            = .SWAPCHAIN_CREATE_INFO_KHR;
        surface          = game_state.render_handle.surface;
        minImageCount    = image_count;
        imageFormat      = surface_format.format;
        imageColorSpace  = surface_format.colorSpace;
        imageExtent      = extent;
        imageArrayLayers = 1;
        imageUsage       = .COLOR_ATTACHMENT_BIT;

        if (!gfx_present_families_same) {
            imageSharingMode      = .CONCURRENT;
            queueFamilyIndexCount = 2;
            pQueueFamilyIndices   = unique_queue_families.data;
        } else {
            imageSharingMode      = .EXCLUSIVE;
            queueFamilyIndexCount = 0;
            pQueueFamilyIndices   = null;
        }

        preTransform   = swap_chain_support.capabilities.currentTransform;
        compositeAlpha = .OPAQUE_BIT_KHR;
        presentMode    = present_mode;
        clipped        = VK_TRUE;
        oldSwapchain   = VK_NULL_HANDLE;
    }

    result := vkCreateSwapchainKHR(logical_device, *swapchain_create_info, null, *swap_chain);

    assert(result == .SUCCESS, "Failed to create swapchain.");

    vkGetSwapchainImagesKHR(logical_device, swap_chain, *image_count, null);
    array_resize(*swap_chain_images, image_count);
    vkGetSwapchainImagesKHR(logical_device, swap_chain, *image_count, swap_chain_images.data);

    swap_chain_image_format = surface_format.format;
    swap_chain_extent       = extent;

}

get_available_vulkan_extensions :: () -> [] VkExtensionProperties {
    extension_count: u32;
    extension_array : [] VkExtensionProperties;

    vkEnumerateInstanceExtensionProperties(null, *extension_count, null);
    array_resize(*extension_array, extension_count);
    vkEnumerateInstanceExtensionProperties(null, *extension_count, extension_array.data);

    return extension_array;
}

//This function makes sure the user defined, platform specific required extensions are supported by your hardware vendor.
check_required_instance_extension_support :: () -> bool {
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

    if CreateDebugUtilsMessengerEXT {
        debug_callback_create_info: VkDebugUtilsMessengerCreateInfoEXT;
        {
            using debug_callback_create_info;

            sType           = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
            messageSeverity = .VERBOSE_BIT_EXT | .WARNING_BIT_EXT | .ERROR_BIT_EXT;
            messageType     = .GENERAL_BIT_EXT | .VALIDATION_BIT_EXT | .PERFORMANCE_BIT_EXT;
            pfnUserCallback = debug_callback;
        }
        CreateDebugUtilsMessengerEXT(instance, *debug_callback_create_info, null, *game_state.render_handle.debug_messenger);
    }
}

create_surface :: () {
    // Platform Specific Call
    result := create_platform_surface();
    assert(result == .VK_SUCCESS, "Failed to create surface");
}

check_required_device_extension_support :: (device : VkPhysicalDevice) -> bool {
    available_extension_count : u32 = 0;
    available_extension_array : [] VkExtensionProperties;

    vkEnumerateDeviceExtensionProperties(device, null, *available_extension_count, null);
    array_resize(*available_extension_array, available_extension_count);
    vkEnumerateDeviceExtensionProperties(device, null, *available_extension_count, available_extension_array.data);

    for required_extension : REQUIRED_DEVICE_EXTENSIONS {
        found : bool = false;

        for available_extension : available_extension_array {
            available_extension_name := cast(string) available_extension.extensionName;
            required_extension_string := to_string(required_extension);
            available_extension_name.count = required_extension_string.count;

            //print("comparing: % to %\n", layer_name_string, layer_property_name);
            if compare(required_extension_string, available_extension_name) == 0 {
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

generate_physical_device_score :: (device : VkPhysicalDevice) -> s64 {
    score := 1;

    device_properties  : VkPhysicalDeviceProperties;
    device_features    : VkPhysicalDeviceFeatures;
    swap_chain_support : bool = false;

    vkGetPhysicalDeviceProperties(device, *device_properties);
    vkGetPhysicalDeviceFeatures(device, *device_features);

    // Favor Discrete GPUs over Integrated GPUs.
    if device_properties.deviceType == {
        case .DISCRETE_GPU;
            score += 1000;
            #through;

        case .INTEGRATED_GPU;
            score += 500;
            #through;

        case; score += 0;
    }

    // Supporting the graphics queue family is required.
    if !find_queue_families(device).graphics_family_valid then return 0;

    // Supporting the required graphics extensions is required (fork found in kitchen)
    if !check_required_device_extension_support(device) {
        return 0;
    } else {
        swap_chain_details : SwapChainSupportDetails = query_swap_chain_support(device);
        swap_chain_support = swap_chain_details.formats.count != 0 && swap_chain_details.present_modes.count != 0;

        if !swap_chain_support {
            return 0;
        }
    }

    return score;
}

pick_physical_device :: () {
    devices      : [..] VkPhysicalDevice;
    device_count : u32 = 0;
    max_score    : s64 = 0;

    physical_device : VkPhysicalDevice = VK_NULL_HANDLE;
    instance := game_state.render_handle.instance;

    vkEnumeratePhysicalDevices(instance, *device_count, null);

    array_resize(*devices, device_count);

    vkEnumeratePhysicalDevices(instance, *device_count, devices.data);

    assert(devices.count != 0);

    for device : devices {
        score := generate_physical_device_score(device);
        if (score > max_score) {
            physical_device = device;
            max_score = score;
        }
    }

    assert(physical_device != VK_NULL_HANDLE, "No GPU with Vulkan support was found.");

    game_state.render_handle.physical_device = physical_device;

}

find_queue_families :: (physical_device : VkPhysicalDevice) -> QueueFamilyIndices {
    indices : QueueFamilyIndices = .{};
    queue_family_count : u32;
    queue_families : [..] VkQueueFamilyProperties;

    vkGetPhysicalDeviceQueueFamilyProperties(physical_device, *queue_family_count, null);
    array_resize(*queue_families, queue_family_count);
    vkGetPhysicalDeviceQueueFamilyProperties(physical_device, *queue_family_count, queue_families.data);

    for queue_family : queue_families {
        present_support : VkBool32 = 0;
        vkGetPhysicalDeviceSurfaceSupportKHR(physical_device, cast (u32) it_index, game_state.render_handle.surface, *present_support);

        if (queue_family.queueFlags & .GRAPHICS_BIT) {
            indices.graphics_family = cast (u32) it_index;
            indices.graphics_family_valid = true;
        }

        if (present_support) {
            indices.present_family = cast (u32) it_index;
            indices.present_family_valid = true;
        }

        if (indices.graphics_family_valid) {
            break;
        }
    }

    return indices;
}

create_logical_device :: () {
    indices : QueueFamilyIndices = find_queue_families(game_state.render_handle.physical_device);
    queue_creation_infos : [..] VkDeviceQueueCreateInfo;
    device_features : VkPhysicalDeviceFeatures = .{};

    unique_queue_families : [..] u32;

    gfx_present_families_same : bool = indices.graphics_family == indices.present_family;

    // @TODO: Clean this up a bit.
    if (gfx_present_families_same) {
        array_add(*unique_queue_families, indices.graphics_family);
    } else {
        array_add(*unique_queue_families, indices.graphics_family);
        array_add(*unique_queue_families, indices.present_family);
    }

    // There are 2 queues, present and graphics. We need to create both of them and bind them
    // to a viable family. There is a chance this family is the same between both of them.
    queue_priority : float = 1.0;
    for family : unique_queue_families {
        queue_create_info : VkDeviceQueueCreateInfo = .{};
        queue_create_info.sType = .DEVICE_QUEUE_CREATE_INFO;
        queue_create_info.queueFamilyIndex = family;
        queue_create_info.queueCount = 1;
        queue_create_info.pQueuePriorities = *queue_priority;
        array_add(*queue_creation_infos, queue_create_info);
    }

    // Logical Device Creation
    logical_device_create_info : VkDeviceCreateInfo = .{};
    {
        using logical_device_create_info;

        sType                   = .DEVICE_CREATE_INFO;
        queueCreateInfoCount    = cast (u32) queue_creation_infos.count;
        pQueueCreateInfos       = queue_creation_infos.data;
        pEnabledFeatures        = *device_features;
        enabledExtensionCount   = REQUIRED_DEVICE_EXTENSIONS.count;
        ppEnabledExtensionNames = REQUIRED_DEVICE_EXTENSIONS.data;

        if (ENABLE_VALIDATION_LAYERS) {
            enabledLayerCount   = cast (u32) REQUIRED_VALIDATION_LAYERS.count;
            ppEnabledLayerNames = REQUIRED_VALIDATION_LAYERS.data;
        } else {
            enabledLayerCount = 0;
        }
    }

    result := vkCreateDevice(game_state.render_handle.physical_device, *logical_device_create_info, null, *game_state.render_handle.logical_device);

    assert(result == .VK_SUCCESS, "Failed to create logical device!");

    vkGetDeviceQueue(game_state.render_handle.logical_device, indices.graphics_family, 0, *game_state.render_handle.graphics_queue);
}

create_image_views :: () {
    using game_state.render_handle;

    array_resize(*swap_chain_image_views, swap_chain_images.count);

    for i: 0..swap_chain_images.count - 1 {
        image_view_create_info : VkImageViewCreateInfo = .{};

        {
            using image_view_create_info;

            sType           =  .IMAGE_VIEW_CREATE_INFO;
            image           =  swap_chain_images[i];
            viewType        =  ._2D;
            format          =  swap_chain_image_format;

            components.r    = .IDENTITY;
            components.g    = .IDENTITY;
            components.b    = .IDENTITY;
            components.a    = .IDENTITY;

            subresourceRange.aspectMask     = .COLOR_BIT;
            subresourceRange.baseMipLevel   = 0;
            subresourceRange.levelCount     = 1;
            subresourceRange.baseArrayLayer = 0;
            subresourceRange.layerCount     = 1;
        }

        result := vkCreateImageView(logical_device, *image_view_create_info, null, *swap_chain_image_views[i]);

        assert(result == .SUCCESS, "Could not create image view %\n", i);
    }
}

create_render_pass :: () {
    using game_state.render_handle;

    color_attachment : VkAttachmentDescription = .{};
    {
        using color_attachment;
        format         = swap_chain_image_format;
        samples        = ._1_BIT;
        loadOp         = .CLEAR;
        storeOp        = .STORE;
        stencilLoadOp  = .DONT_CARE;
        stencilStoreOp = .DONT_CARE;
        initialLayout  = .UNDEFINED;
        finalLayout    = .PRESENT_SRC_KHR;
    }
    
    color_attachment_reference : VkAttachmentReference = .{};
    {
        using color_attachment_reference;
        attachment = 0;
        layout     = .COLOR_ATTACHMENT_OPTIMAL;
    }
    
    subpass : VkSubpassDescription = .{};
    {
        using subpass;
        pipelineBindPoint    = .GRAPHICS;
        colorAttachmentCount = 1;
        pColorAttachments    = *color_attachment_reference;
    }
    
    render_pass_create_info : VkRenderPassCreateInfo = .{};
    {
        using render_pass_create_info;
        sType = .RENDER_PASS_CREATE_INFO;
        attachmentCount = 1;
        pAttachments    = *color_attachment;
        subpassCount    = 1;
        pSubpasses      = *subpass;
    }
    
    result := vkCreateRenderPass(logical_device, *render_pass_create_info, null, *render_pass);
    
    assert (result == .SUCCESS, "Could not create render pass.");
}

create_shader_module :: (code : [] u8) -> VkShaderModule {
    using game_state.render_handle;

    shader_module      : VkShaderModule;
    
    module_create_info : VkShaderModuleCreateInfo = .{};
    {
        using module_create_info;
        sType    = .SHADER_MODULE_CREATE_INFO;
        codeSize = xx code.count;
        pCode    = cast (*u32) code.data;
    }
        
    result := vkCreateShaderModule(logical_device, *module_create_info, null, *shader_module);
    
    assert(result == .SUCCESS, "Could not create shader module");
    
    return shader_module;
}

create_render_pipeline :: () {
    using game_state.render_handle;

    vert, vert_loaded := read_entire_file("C:/Users/RyDaw/Documents/jaivox/shaders/mono/shader.vert.spv");
    frag, frag_loaded := read_entire_file("C:/Users/RyDaw/Documents/jaivox/shaders/mono/shader.frag.spv");

    vert_shader_module := create_shader_module(cast ([] u8)vert);
    frag_shader_module := create_shader_module(cast ([] u8)frag);
    
    vert_shader_stage_info : VkPipelineShaderStageCreateInfo = .{};
    {
        using vert_shader_stage_info;
        sType  = .PIPELINE_SHADER_STAGE_CREATE_INFO;
        stage  = .VERTEX_BIT;
        module = vert_shader_module;
        pName  = "main";
    }
    
    frag_shader_stage_info : VkPipelineShaderStageCreateInfo = .{};
    {
        using frag_shader_stage_info;
        sType  = .PIPELINE_SHADER_STAGE_CREATE_INFO;
        stage  = .FRAGMENT_BIT;
        module = frag_shader_module;
        pName  = "main";
    }
    
    shader_stages := VkPipelineShaderStageCreateInfo.[vert_shader_stage_info, 
                                                      frag_shader_stage_info];
                                                      
    dynamic_states := VkDynamicState.[.VIEWPORT, .SCISSOR];
    dynamic_state : VkPipelineDynamicStateCreateInfo = .{};
    {
        using dynamic_state;
        sType             = .PIPELINE_DYNAMIC_STATE_CREATE_INFO;
        dynamicStateCount = cast (u32) dynamic_states.count;
        pDynamicStates    = dynamic_states.data;
    }
    
    vertex_input_info : VkPipelineVertexInputStateCreateInfo = .{};
    {
        using vertex_input_info;
        sType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
        vertexBindingDescriptionCount   = 0;
        pVertexBindingDescriptions      = null;
        vertexAttributeDescriptionCount = 0;
        pVertexAttributeDescriptions    = null;
    }
    
    input_assembly : VkPipelineInputAssemblyStateCreateInfo = .{};
    {
        using input_assembly;
        sType                  = .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
        topology               = .TRIANGLE_LIST;
        primitiveRestartEnable = VK_FALSE;
    }
    
    viewport : VkViewport = .{};
    {
        using viewport;
        x = 0.0;
        y = 0.0;
        width  = cast (float) swap_chain_extent.width;
        height = cast (float) swap_chain_extent.height;
        minDepth = 0.0;
        maxDepth = 1.0;
    }
    
    scissor : VkRect2D = .{};
    {
        using scissor;
        offset = .{0, 0};
        extent = swap_chain_extent;
    }
    
    viewport_state : VkPipelineViewportStateCreateInfo = .{};
    {
        using viewport_state;
        sType         = .PIPELINE_VIEWPORT_STATE_CREATE_INFO;
        viewportCount = 1;
        scissorCount  = 1;
        pViewports    = *viewport;
        pScissors     = *scissor;
    }
    
    rasterizer : VkPipelineRasterizationStateCreateInfo = .{};
    {
        using rasterizer;
        sType                   = .PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
        depthClampEnable        = VK_FALSE;
        rasterizerDiscardEnable = VK_FALSE;
        polygonMode             = .FILL;
        lineWidth               = 1.0;
        cullMode                = .BACK_BIT;
        frontFace               = .CLOCKWISE;
        depthBiasEnable         = VK_FALSE;
        depthBiasConstantFactor = 0.0;
        depthBiasClamp          = 0.0;
        depthBiasSlopeFactor    = 0.0;
    }
    
    multisampling : VkPipelineMultisampleStateCreateInfo = .{};
    {
        using multisampling;
        sType = .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
        sampleShadingEnable   = VK_FALSE;
        rasterizationSamples  = ._1_BIT;
        minSampleShading      = 1.0;
        pSampleMask           = null;
        alphaToCoverageEnable = VK_FALSE;
        alphaToOneEnable      = VK_FALSE;
    }
    
    color_blend_attachment : VkPipelineColorBlendAttachmentState = .{};
    {
        using color_blend_attachment;
        colorWriteMask      = .R_BIT | .G_BIT | .B_BIT | .A_BIT;
        blendEnable         = VK_TRUE;
        srcColorBlendFactor = .SRC_ALPHA;
        dstColorBlendFactor = .ONE_MINUS_SRC_ALPHA;
        colorBlendOp        = .ADD;
        srcAlphaBlendFactor = .ONE;
        dstAlphaBlendFactor = .ZERO;
        alphaBlendOp        = .ADD;
    }
    
    color_blending : VkPipelineColorBlendStateCreateInfo = .{};
    {
        using color_blending;
        sType = .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
        logicOpEnable      = VK_FALSE;
        logicOp            = .COPY;
        attachmentCount    = 1;
        pAttachments       = *color_blend_attachment;
        blendConstants [0] = 0.0;
        blendConstants [1] = 0.0;
        blendConstants [2] = 0.0;
        blendConstants [3] = 0.0;        
    }
     
    pipeline_layout_create_info : VkPipelineLayoutCreateInfo = .{};
    {
        using pipeline_layout_create_info;
        sType = .PIPELINE_LAYOUT_CREATE_INFO;
        setLayoutCount         = 0;
        pSetLayouts            = null;
        pushConstantRangeCount = 0;
        pPushConstantRanges    = null;
    }
    result := vkCreatePipelineLayout(logical_device, *pipeline_layout_create_info, null, *pipeline_layout);
    
    assert(result == .SUCCESS, "Could not create Vulkan Pipeline Layout");
    
    pipeline_creation_info : VkGraphicsPipelineCreateInfo = .{};
    {
        using pipeline_creation_info;
        sType = .GRAPHICS_PIPELINE_CREATE_INFO;
        stageCount          = 2;
        pStages             = shader_stages.data;
        pVertexInputState   = *vertex_input_info;
        pInputAssemblyState = *input_assembly;
        pViewportState      = *viewport_state;
        pRasterizationState = *rasterizer;
        pMultisampleState   = *multisampling;
        pDepthStencilState  = null;
        pColorBlendState    = *color_blending;
        pDynamicState       = *dynamic_state;
        layout              = pipeline_layout;
        renderPass          = render_pass;
        subpass             = 0;
        basePipelineHandle  = VK_NULL_HANDLE;
        basePipelineIndex   = -1;
    }
    
    result = vkCreateGraphicsPipelines(logical_device, VK_NULL_HANDLE, 1, *pipeline_creation_info, null, *graphics_pipeline);
    
    assert(result == .SUCCESS, "Failed to create graphics pipeline");
    
    vkDestroyShaderModule(logical_device, frag_shader_module, null);
    vkDestroyShaderModule(logical_device, vert_shader_module, null);
}

create_framebuffers :: () {
    using game_state.render_handle;
    
    array_resize(*swap_chain_framebuffers, swap_chain_image_views.count);
    
    for * swap_chain_image_views {
        attachments := VkImageView.[
            swap_chain_image_views[it_index]
        ];
            
        
        frame_buffer_create_info : VkFramebufferCreateInfo = .{};
        {
            using frame_buffer_create_info;
            
            sType = .FRAMEBUFFER_CREATE_INFO;
            renderPass      = render_pass;
            attachmentCount = 1;
            pAttachments    = attachments.data;
            width           = swap_chain_extent.width;
            height          = swap_chain_extent.height;
            layers          = 1;
        }
        
        result := vkCreateFramebuffer(logical_device, *frame_buffer_create_info, null, *swap_chain_framebuffers[it_index]);
        
        assert(result == .SUCCESS, "Could not create framebuffer");
    }
}

#scope_file
#import "Vulkan";
#import "File";
#import "Window_Creation";
