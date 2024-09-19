load_platform_extensions :: () -> [..] *u8 {
    extensions : [..] *u8;
    array_add(*extensions, VK_KHR_SURFACE_EXTENSION_NAME.data);
    array_add(*extensions, VK_KHR_WIN32_SURFACE_EXTENSION_NAME.data);
    array_add(*extensions, VK_EXT_DEBUG_UTILS_EXTENSION_NAME.data);
    array_add(*extensions, VK_EXT_DEBUG_UTILS_EXTENSION_NAME.data);

    
    return extensions;
}

create_platform_surface :: () -> VkResult {
    surface_create_info : VkWin32SurfaceCreateInfoKHR;
    surface_create_info.sType     =  .WIN32_SURFACE_CREATE_INFO_KHR;
    surface_create_info.hinstance =          GetModuleHandleW(null);
    surface_create_info.hwnd      = game_state.render_handle.window;
    result := vkCreateWin32SurfaceKHR(game_state.render_handle.instance, *surface_create_info, null, *game_state.render_handle.surface);
    
    return result;
}

#scope_file
#import "Vulkan";
#import "Windows";