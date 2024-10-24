#if DEBUG {
    ENABLE_VALIDATION_LAYERS :: true;
} else {
    ENABLE_VALIDATION_LAYERS :: false;
}

MAX_FRAMES_IN_FLIGHT : int : 2;

REQUIRED_DEVICE_EXTENSIONS :: (*u8).[VK_KHR_SWAPCHAIN_EXTENSION_NAME];

// These are only "Required" By the programmers and will not be considered for release builds.
REQUIRED_VALIDATION_LAYERS :: (*u8).["VK_LAYER_KHRONOS_validation"];

RenderHandle :: struct {
    window                     : Window_Type;
    instance                   : VkInstance               = null;
    surface                    : VkSurfaceKHR             = VK_NULL_HANDLE;
    debug_messenger            : VkDebugUtilsMessengerEXT = null;
    physical_device            : VkPhysicalDevice         = VK_NULL_HANDLE;
    logical_device             : VkDevice                 = VK_NULL_HANDLE;
    graphics_queue             : VkQueue                  = null;
    present_queue              : VkQueue                  = null;
    swap_chain                 : VkSwapchainKHR           = null;
    swap_chain_images          : [..] VkImage;
    swap_chain_image_views     : [..] VkImageView;
    swap_chain_image_format    : VkFormat;
    swap_chain_extent          : VkExtent2D;
    render_pass                : VkRenderPass;
    descriptor_set_layout      : VkDescriptorSetLayout;
    pipeline_layout            : VkPipelineLayout;
    graphics_pipeline          : VkPipeline;
    swap_chain_framebuffers    : [..] VkFramebuffer;
    command_pool               : VkCommandPool;
    command_buffers            : [..] VkCommandBuffer;
    image_available_semaphores : [..] VkSemaphore;
    render_finished_semaphores : [..] VkSemaphore;
    in_flight_fences           : [..] VkFence;
    framebuffer_resized        : bool                     = false;
    current_frame              : u32                      = 0;
    vertex_buffer              : VkBuffer;
    vertex_buffer_memory       : VkDeviceMemory;
    index_buffer               : VkBuffer;
    index_buffer_memory        : VkDeviceMemory;
    uniform_buffers            : [..] VkBuffer;
    uniform_buffers_memory     : [..] VkDeviceMemory;
    uniform_buffers_mapped     : [..] *void;
    descriptor_pool            : VkDescriptorPool;
    descriptor_sets            : [..] VkDescriptorSet;
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
    create_vulkan_instance();       // Create Vulkan API Instance
    setup_debug_messenger();        // Create Vulkan Debug Messenger
    create_surface();               // Create Vulkan Surface to render to Game Window
    pick_physical_device();         // Select GPU for rendering
    create_logical_device();        // Create Vulkan Logic Profile on GPU
    create_swap_chain();            // Create Image Chain Buffer
    create_image_views();           // Create Views for each Image
    create_render_pass();           // Create Render Pass for Pipeline Config
    create_descriptor_set_layout(); // Create Buffer Layout
    create_render_pipeline();       // Create Render Pipeline
    create_framebuffers();          // Create Frame Buffers
    create_command_pool();          // Create Command Pools
    create_vertex_buffer();         // Create Buffer to transfer Verts to GPU
    create_index_buffer();          // Create Buffer to manage Vertex transfer
    create_uniform_buffers();       // Create uniform data for draw calls
    create_descriptor_pool();       // Create descriptor pool info
    create_descriptor_sets();       // Create descriptor set for each buffer
    create_command_buffers();       // Create Command Buffer
    create_sync_objects();          // Create Sync Objects for Control Flow
}

// Proxy Functions. These get real values in setup_debug_messenger()
CreateDebugUtilsMessengerEXT   : PFN_vkCreateDebugUtilsMessengerEXT;
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

cleanup_render :: () {
    using game_state.render_handle;
    
    cleanup_swap_chain();
    
    for i: 0..MAX_FRAMES_IN_FLIGHT - 1 {
        vkDestroyBuffer(logical_device, uniform_buffers[i], null);
        vkFreeMemory(logical_device, uniform_buffers_memory[i], null);
    }
    
    vkDestroyDescriptorPool(logical_device, descriptor_pool, null);
    
    vkDestroyDescriptorSetLayout(logical_device, descriptor_set_layout, null);
    
    vkDestroyBuffer(logical_device, index_buffer, null);
    vkFreeMemory(logical_device, index_buffer_memory, null);
    
    vkDestroyBuffer(logical_device, vertex_buffer, null);
    vkFreeMemory(logical_device, vertex_buffer_memory, null);
    
    vkDestroyPipeline(logical_device, graphics_pipeline, null);
    vkDestroyPipelineLayout(logical_device, pipeline_layout, null);
    vkDestroyRenderPass(logical_device, render_pass, null);

    for i: 0..(MAX_FRAMES_IN_FLIGHT - 1) {
        vkDestroySemaphore(logical_device, image_available_semaphores[i], null);
        vkDestroySemaphore(logical_device, render_finished_semaphores[i], null);
        vkDestroyFence(logical_device, in_flight_fences[i], null);
    }

    vkDestroyCommandPool(logical_device, command_pool, null);

    vkDestroyDevice(logical_device, null);

    if ENABLE_VALIDATION_LAYERS {
        DestroyDebugUtilsMessengerEXT(instance, debug_messenger, null);
    }

    vkDestroySurfaceKHR(instance, surface, null);
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
        extent.width  = xx clamp(WindowCreationInfo.width, cast (s32) capabilities.minImageExtent.width, cast (s32) capabilities.maxImageExtent.width);
        extent.height = xx clamp(WindowCreationInfo.height, cast (s32) capabilities.minImageExtent.height, cast (s32) capabilities.maxImageExtent.height);
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

cleanup_swap_chain :: () {
    using game_state.render_handle;

    for buffer : swap_chain_framebuffers {
        vkDestroyFramebuffer(logical_device, buffer, null);
    }
    
    for image : swap_chain_image_views {
        vkDestroyImageView(logical_device, image, null);
    }
    
    vkDestroySwapchainKHR(logical_device, swap_chain, null);
}

recreate_swap_chain :: () {
    using game_state.render_handle;
    
    width, height := get_window_dimensions(xx window);
	
	if width == 0 || height == 0 {
        return;
	}
	
    vkDeviceWaitIdle(logical_device);
    
	swap_chain_extent.width = xx width;
	swap_chain_extent.height == xx height;
    
    cleanup_swap_chain();
    
    create_swap_chain();
    create_image_views();
    create_framebuffers();
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
            messageSeverity = .VERBOSE_BIT_EXT | .WARNING_BIT_EXT    | .ERROR_BIT_EXT;
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
    vkGetDeviceQueue(game_state.render_handle.logical_device, indices.present_family, 0, *game_state.render_handle.present_queue);

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

    subpass_dependency : VkSubpassDependency = .{};
    {
        using subpass_dependency;

        srcSubpass       = VK_SUBPASS_EXTERNAL;
        dstSubpass       = 0;
        srcStageMask     = .COLOR_ATTACHMENT_OUTPUT_BIT;
        srcAccessMask    = 0;
        dstStageMask     = .COLOR_ATTACHMENT_OUTPUT_BIT;
        dstAccessMask    = .COLOR_ATTACHMENT_WRITE_BIT;
    }

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
        attachmentCount  = 1;
        pAttachments     = *color_attachment;
        subpassCount     = 1;
        pSubpasses       = *subpass;
        dependencyCount  = 1;
        pDependencies    = *subpass_dependency;
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

create_descriptor_set_layout :: () {
    using game_state.render_handle;

    ubo_layout_binding : VkDescriptorSetLayoutBinding = .{};
    {
        using ubo_layout_binding;
        
        binding             = 0;
        descriptorType      = .UNIFORM_BUFFER;
        descriptorCount     = 1;
        stageFlags          = .VERTEX_BIT;
        pImmutableSamplers  = null;
    }
    
    layout_create_info : VkDescriptorSetLayoutCreateInfo = .{};
    {
        using layout_create_info;
        
        sType = .DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
        bindingCount = 1;
        pBindings    = *ubo_layout_binding;
    }
    
    result := vkCreateDescriptorSetLayout(logical_device, *layout_create_info, null, *descriptor_set_layout);
    
    assert(result == .SUCCESS, "Could not create descriptor set layout");
}

create_render_pipeline :: () {
    using game_state.render_handle;

    vert_file_location := tprint("%/shaders/mono/shader.vert.spv", get_program_data_dir());
    frag_file_location := tprint("%/shaders/mono/shader.frag.spv", get_program_data_dir());

    vert, vert_loaded := read_entire_file(vert_file_location);
    frag, frag_loaded := read_entire_file(frag_file_location);

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
    
    binding_description    := get_binding_description();
    attribute_descriptions := get_attribute_descriptions();
    
    vertex_input_info : VkPipelineVertexInputStateCreateInfo = .{};
    {
        using vertex_input_info;
        sType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
        vertexBindingDescriptionCount   = 1;
        pVertexBindingDescriptions      = *binding_description;
        vertexAttributeDescriptionCount = xx attribute_descriptions.count;
        pVertexAttributeDescriptions    = attribute_descriptions.data;
    }

    input_assembly : VkPipelineInputAssemblyStateCreateInfo = .{};
    {
        using input_assembly;
        sType                  = .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
        topology               = .TRIANGLE_LIST;
        primitiveRestartEnable = VK_FALSE;
    }

    viewport_state : VkPipelineViewportStateCreateInfo = .{};
    {
        using viewport_state;
        sType         = .PIPELINE_VIEWPORT_STATE_CREATE_INFO;
        viewportCount = 1;
        scissorCount  = 1;
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
        frontFace               = .COUNTER_CLOCKWISE;
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
        setLayoutCount         = 1;
        pSetLayouts            = *descriptor_set_layout;
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

create_buffer :: (size : VkDeviceSize, usage  : VkBufferUsageFlags, properties : VkMemoryPropertyFlags,
                                       buffer : *VkBuffer,        buffer_memory : *VkDeviceMemory)     {
    using game_state.render_handle;
    
    buffer_create_info : VkBufferCreateInfo = .{};
    buffer_create_info.sType       = .BUFFER_CREATE_INFO;
    buffer_create_info.size        = size;
    buffer_create_info.usage       = usage;
    buffer_create_info.sharingMode = .EXCLUSIVE;  
    
    result := vkCreateBuffer(logical_device, *buffer_create_info, null, buffer);
    
    assert(result == .SUCCESS, "Failed to create Vertex Buffer");
    
    memory_requirements : VkMemoryRequirements;   
    vkGetBufferMemoryRequirements(logical_device, <<buffer, *memory_requirements);

    allocate_info : VkMemoryAllocateInfo = .{};
    {
        using allocate_info;
        
        sType = .MEMORY_ALLOCATE_INFO;
        allocationSize = memory_requirements.size;
        memoryTypeIndex = find_memory_type(memory_requirements.memoryTypeBits, properties);
    }
    
    result = vkAllocateMemory(logical_device, *allocate_info, null, buffer_memory);
    
    assert(result == .SUCCESS, "Failed to allocate VBuffer Memory");
    
    vkBindBufferMemory(logical_device, <<buffer, <<buffer_memory, 0);
}

copy_buffer :: (src_buffer : VkBuffer, dst_buffer : VkBuffer, size : VkDeviceSize) {
    using game_state.render_handle;

    allocate_info : VkCommandBufferAllocateInfo = .{};
    {
        using allocate_info;
        
        sType = .COMMAND_BUFFER_ALLOCATE_INFO;
        level = .PRIMARY;
        commandPool = command_pool;
        commandBufferCount = 1;
    }
    
    command_buffer : VkCommandBuffer;
    vkAllocateCommandBuffers(logical_device, *allocate_info, *command_buffer);
    
    begin_info : VkCommandBufferBeginInfo = .{};
    {
        using begin_info;
        
        sType = .COMMAND_BUFFER_BEGIN_INFO;
        flags = .ONE_TIME_SUBMIT_BIT;
    }
    
    vkBeginCommandBuffer(command_buffer, *begin_info);
    
    copy_region : VkBufferCopy = .{};
    copy_region.size = size;
    vkCmdCopyBuffer(command_buffer, src_buffer, dst_buffer, 1, *copy_region);
    
    vkEndCommandBuffer(command_buffer);
    
    submit_info : VkSubmitInfo = .{};
    {
        using submit_info;
        
        sType = .SUBMIT_INFO;
        commandBufferCount = 1;
        pCommandBuffers = *command_buffer;
    }
    
    vkQueueSubmit(graphics_queue, 1, *submit_info, VK_NULL_HANDLE);
    vkQueueWaitIdle(graphics_queue);
    
    vkFreeCommandBuffers(logical_device, command_pool, 1, *command_buffer);
}

create_vertex_buffer :: () {
    using game_state.render_handle;
    
    buffer_size : VkDeviceSize = cast (u64) (size_of(Vertex) * VERTS.count);
    
    staging_buffer : VkBuffer;
    staging_buffer_memory : VkDeviceMemory;
    
    create_buffer(buffer_size, .TRANSFER_SRC_BIT, .HOST_VISIBLE_BIT | .HOST_COHERENT_BIT, *staging_buffer, *staging_buffer_memory);

    data : *void;    
    vkMapMemory(logical_device, staging_buffer_memory, 0, buffer_size, 0, *data);
    memcpy(data, VERTS.data, xx buffer_size);
    vkUnmapMemory(logical_device, staging_buffer_memory);
    
    create_buffer(buffer_size, .TRANSFER_DST_BIT | .VERTEX_BUFFER_BIT, .DEVICE_LOCAL_BIT, *vertex_buffer, *vertex_buffer_memory);
    
    copy_buffer(staging_buffer, vertex_buffer, buffer_size);
    
    vkDestroyBuffer(logical_device, staging_buffer, null);
    vkFreeMemory(logical_device, staging_buffer_memory, null);
}

create_index_buffer :: () {
    using game_state.render_handle;
    
    buffer_size : VkDeviceSize = cast (u64) (size_of(u16) * INDICES.count);
    
    staging_buffer : VkBuffer;
    staging_buffer_memory : VkDeviceMemory;
    
    create_buffer(buffer_size, .TRANSFER_SRC_BIT, .HOST_VISIBLE_BIT | .HOST_COHERENT_BIT, *staging_buffer, *staging_buffer_memory);

    data : *void;    
    vkMapMemory(logical_device, staging_buffer_memory, 0, buffer_size, 0, *data);
    memcpy(data, INDICES.data, xx buffer_size);
    vkUnmapMemory(logical_device, staging_buffer_memory);
    
    create_buffer(buffer_size, .TRANSFER_DST_BIT | .INDEX_BUFFER_BIT, .DEVICE_LOCAL_BIT, *index_buffer, *index_buffer_memory);
    
    copy_buffer(staging_buffer, index_buffer, buffer_size);
    
    vkDestroyBuffer(logical_device, staging_buffer, null);
    vkFreeMemory(logical_device, staging_buffer_memory, null);
}

create_uniform_buffers :: () {
    using game_state.render_handle;

    buffer_size : VkDeviceSize = #run size_of(UniformBufferObject);
    
    array_resize(*uniform_buffers, MAX_FRAMES_IN_FLIGHT);
    array_resize(*uniform_buffers_memory, MAX_FRAMES_IN_FLIGHT);
    array_resize(*uniform_buffers_mapped, MAX_FRAMES_IN_FLIGHT);
    
    for i: 0..MAX_FRAMES_IN_FLIGHT - 1 {
        create_buffer(buffer_size, .UNIFORM_BUFFER_BIT, .HOST_VISIBLE_BIT | .HOST_COHERENT_BIT, *uniform_buffers[i], *uniform_buffers_memory[i]);
        vkMapMemory(logical_device, uniform_buffers_memory[i], 0, buffer_size, 0, *uniform_buffers_mapped[i]);
    }
    
}

create_descriptor_pool :: () {
    using game_state.render_handle;
    
    pool_size : VkDescriptorPoolSize = .{};
    {
        using pool_size;
        
        type = .UNIFORM_BUFFER;
        descriptorCount = xx MAX_FRAMES_IN_FLIGHT;
    }
    
    pool_create_info : VkDescriptorPoolCreateInfo = .{};
    {
        using pool_create_info;
        
        sType = .DESCRIPTOR_POOL_CREATE_INFO;
        poolSizeCount   = 1;
        pPoolSizes      = *pool_size;
        maxSets         = xx MAX_FRAMES_IN_FLIGHT;
    }
    
    result := vkCreateDescriptorPool(logical_device, *pool_create_info, null, *descriptor_pool);
    
    assert (result == .SUCCESS, "Could not create descriptor pool");
}

create_descriptor_sets :: () {
    using game_state.render_handle;

    layouts : [..] VkDescriptorSetLayout;
    for i: 0..MAX_FRAMES_IN_FLIGHT - 1 {
        array_add(*layouts, descriptor_set_layout);
    }
    
    allocate_info : VkDescriptorSetAllocateInfo = .{};
    {
        using allocate_info;
        
        sType = .DESCRIPTOR_SET_ALLOCATE_INFO;
        descriptorPool = descriptor_pool;
        descriptorSetCount = xx MAX_FRAMES_IN_FLIGHT;
        pSetLayouts = layouts.data;
    }
    
    array_resize(*descriptor_sets, MAX_FRAMES_IN_FLIGHT);
    result := vkAllocateDescriptorSets(logical_device, *allocate_info, descriptor_sets.data);
    
    assert(result == .SUCCESS, "Could not allocate descriptor sets"); 
    
    for i: 0..MAX_FRAMES_IN_FLIGHT - 1 {
        buffer_info : VkDescriptorBufferInfo = .{};
        {
            using buffer_info;
            
            buffer = uniform_buffers[i];
            offset = 0;
            range  = #run size_of(UniformBufferObject);
        }
        
        descriptor_write : VkWriteDescriptorSet = .{};
        {
            using descriptor_write;
            
            sType = .WRITE_DESCRIPTOR_SET;
            dstSet           = descriptor_sets[i];
            dstBinding       = 0;
            dstArrayElement  = 0;
            descriptorType   = .UNIFORM_BUFFER;
            descriptorCount  = 1;
            pBufferInfo      = *buffer_info;
            pImageInfo       = null;
            pTexelBufferView = null;
        }
        
        vkUpdateDescriptorSets(logical_device, 1, *descriptor_write, 0, null);
    }
    
}

create_command_pool :: () {
    using game_state.render_handle;

    indices : QueueFamilyIndices = find_queue_families(physical_device);

    command_pool_create_info : VkCommandPoolCreateInfo = .{};
    {
        using command_pool_create_info;
        sType = .COMMAND_POOL_CREATE_INFO;
        flags = .RESET_COMMAND_BUFFER_BIT;
        queueFamilyIndex = indices.graphics_family;
    }

    result := vkCreateCommandPool(logical_device, *command_pool_create_info, null, *command_pool);

    assert (result == .SUCCESS, "Could not create command pool");
}

create_command_buffers :: () {
    using game_state.render_handle;

    array_resize(*command_buffers, MAX_FRAMES_IN_FLIGHT);

    command_buffer_alloc_info : VkCommandBufferAllocateInfo = .{};
    {
        using command_buffer_alloc_info;

        sType = .COMMAND_BUFFER_ALLOCATE_INFO;
        commandPool        = command_pool;
        level              = .PRIMARY;
        commandBufferCount = xx command_buffers.count;
    }

    result := vkAllocateCommandBuffers(logical_device, *command_buffer_alloc_info, command_buffers.data);

    assert(result == .SUCCESS, "Could not allocate command buffer.");
}

record_command_buffer :: (in_command_buffer : VkCommandBuffer, image_index : u32) {
    using game_state.render_handle;

    clear_value : VkClearValue = .{.{float.[0, 0, 0, 1]}};

    command_buffer_begin_info : VkCommandBufferBeginInfo = .{};
    {
        using command_buffer_begin_info;
        sType = .COMMAND_BUFFER_BEGIN_INFO;
        flags = 0;
        pInheritanceInfo = null;
    }

    result := vkBeginCommandBuffer(in_command_buffer, *command_buffer_begin_info);

    assert(result == .SUCCESS, "Failed to begin recording command buffer.");

    render_pass_begin_info : VkRenderPassBeginInfo = .{};
    {
        using render_pass_begin_info;
        sType = .RENDER_PASS_BEGIN_INFO;
        renderPass        = render_pass;
        framebuffer       = swap_chain_framebuffers[image_index];
        renderArea.offset = .{0, 0};
        renderArea.extent = swap_chain_extent;
        clearValueCount   = 1;
        pClearValues      = *clear_value;
    }

    vkCmdBeginRenderPass(in_command_buffer, *render_pass_begin_info, .INLINE);
    vkCmdBindPipeline(in_command_buffer, .GRAPHICS, graphics_pipeline);
    
    vertex_buffers := VkBuffer.[vertex_buffer];
    offsets        := VkDeviceSize.[0];
    
    vkCmdBindVertexBuffers(in_command_buffer, 0, 1, vertex_buffers.data, offsets.data);

    vkCmdBindIndexBuffer(in_command_buffer, index_buffer, 0, .UINT16);

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
    vkCmdSetViewport(in_command_buffer, 0, 1, *viewport);

    scissor : VkRect2D = .{};
    {
        using scissor;
        offset = .{0, 0};
        extent = swap_chain_extent;
    }
    vkCmdSetScissor(in_command_buffer, 0, 1, *scissor);
    
    vkCmdBindDescriptorSets(in_command_buffer, .GRAPHICS, pipeline_layout, 0, 1, *descriptor_sets[current_frame], 0, null);
    vkCmdDrawIndexed(in_command_buffer, xx INDICES.count, 1, 0, 0, 0);

    vkCmdEndRenderPass(in_command_buffer);

    result = vkEndCommandBuffer(in_command_buffer);

    assert(result == .SUCCESS, "Failed to record command buffer.");
}

create_sync_objects :: () {
    using game_state.render_handle;

    array_resize(*image_available_semaphores, MAX_FRAMES_IN_FLIGHT);
    array_resize(*render_finished_semaphores, MAX_FRAMES_IN_FLIGHT);
    array_resize(*in_flight_fences, MAX_FRAMES_IN_FLIGHT);

    semaphore_create_info : VkSemaphoreCreateInfo = .{};
    {
        using semaphore_create_info;

        sType = .SEMAPHORE_CREATE_INFO;
    }

    fence_create_info : VkFenceCreateInfo = .{};
    {
        using fence_create_info;

        sType = .FENCE_CREATE_INFO;
        flags = .SIGNALED_BIT;
    }

    for i: 0..(MAX_FRAMES_IN_FLIGHT - 1) {
        vkCreateSemaphore(logical_device, *semaphore_create_info, null, *image_available_semaphores[i]);
        vkCreateSemaphore(logical_device, *semaphore_create_info, null, *render_finished_semaphores[i]);
        vkCreateFence(logical_device, *fence_create_info, null, *in_flight_fences[i]);
    }

}

update_uniform_buffer :: (current_image : u32) {
    using game_state.render_handle;

    model_rotate : Quaternion;
    set_from_axis_and_angle(*model_rotate, 0, 0, 1, square_rotation);

    ubo : UniformBufferObject = .{};
    {
        using ubo;
        
        model = transpose(rotation_matrix(Matrix4, model_rotate));
        view  = transpose(make_look_at_matrix(.{2, 2, 2}, .{0, 0, 0}, .{0, 0, 1}, false));
        proj  = transpose(make_projection_matrix(45.0 * PI / 180.0, xx (swap_chain_extent.width / swap_chain_extent.height), 0.1, 100.0));
    }
    
    ubo.proj.coef[1][1] *= -1;
    
    memcpy(uniform_buffers_mapped[current_image], *ubo, size_of(UniformBufferObject));
}

draw_frame :: () {
    using game_state.render_handle;
    image_index : u32;

    vkWaitForFences(logical_device, 1, *in_flight_fences[current_frame], VK_TRUE, U64_MAX);
    vkResetFences(logical_device, 1, *in_flight_fences[current_frame]);

    result := vkAcquireNextImageKHR(logical_device, swap_chain, U64_MAX, image_available_semaphores[current_frame], VK_NULL_HANDLE, *image_index);

    if result == .ERROR_OUT_OF_DATE_KHR {
        recreate_swap_chain();
        return;
    } else if result != .SUCCESS && result != .SUBOPTIMAL_KHR {
        assert(false, "Failed to acquire swap chain image");
    }
    
    vkResetFences(logical_device, 1, *in_flight_fences[current_frame]);

    wait_semaphores   := VkSemaphore.[image_available_semaphores[current_frame]];
    wait_stages       := VkPipelineStageFlags.[.COLOR_ATTACHMENT_OUTPUT_BIT];
    signal_semaphores := VkSemaphore.[render_finished_semaphores[current_frame]];
    swap_chains       := VkSwapchainKHR.[swap_chain];

    vkResetCommandBuffer(command_buffers[current_frame], 0);
    record_command_buffer(command_buffers[current_frame], image_index);
    
    update_uniform_buffer(current_frame);

    submit_info : VkSubmitInfo = .{};
    {
        using submit_info;

        sType =.SUBMIT_INFO;

        waitSemaphoreCount   = 1;
        pWaitSemaphores      = wait_semaphores.data;
        pWaitDstStageMask    = wait_stages.data;
        commandBufferCount   = 1;
        pCommandBuffers      = *command_buffers[current_frame];
        signalSemaphoreCount = 1;
        pSignalSemaphores    = signal_semaphores.data;
    }

    result = vkQueueSubmit(graphics_queue, 1, *submit_info, in_flight_fences[current_frame]);

    assert(result == .SUCCESS, "Failed to submit draw command buffer");

    present_info : VkPresentInfoKHR = .{};
    {
        using present_info;
        sType = .PRESENT_INFO_KHR;

        waitSemaphoreCount = 1;
        pWaitSemaphores    = signal_semaphores.data;
        swapchainCount     = 1;
        pSwapchains        = swap_chains.data;
        pImageIndices      = *image_index;
        pResults           = null;
    }

    result = vkQueuePresentKHR(present_queue, *present_info);

    if result == .ERROR_OUT_OF_DATE_KHR || result == .SUBOPTIMAL_KHR || framebuffer_resized {
        framebuffer_resized = false;
        recreate_swap_chain();
    }
    
    current_frame = (current_frame + 1) % xx MAX_FRAMES_IN_FLIGHT;
    
    vkDeviceWaitIdle(logical_device);
}

get_binding_description :: () -> VkVertexInputBindingDescription {
    binding_description : VkVertexInputBindingDescription = .{};
    {
        using binding_description;
        
        binding = 0;
        stride  = size_of(Vertex);
        inputRate = .VERTEX;
    }
    
    return binding_description;
}

get_attribute_descriptions :: () -> [2] VkVertexInputAttributeDescription {
    attribute_descriptions : [2] VkVertexInputAttributeDescription;
    {
        using attribute_descriptions[0];
        
        binding  = 0;
        location = 0;
        format   = .R32G32B32_SFLOAT;
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

find_memory_type :: (filter : u32, properties : VkMemoryPropertyFlags) -> u32 {
    using game_state.render_handle;
    
    memory_properties : VkPhysicalDeviceMemoryProperties;
    vkGetPhysicalDeviceMemoryProperties(physical_device, *memory_properties);
    
    for i: 0..memory_properties.memoryTypeCount -1 {
        if (filter & (1 << i) && (memory_properties.memoryTypes[i].propertyFlags & properties) == properties) {
            return i;
        }
    }
    
    assert(false, "Could not find suitable memory type");
    return 0;
}


#scope_file
#if OS == {
    case .WINDOWS;
        #load "vulkan_windows.jai";
    case;
}

#import "Vulkan";
