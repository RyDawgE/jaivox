load_platform_extensions :: () -> [..] *u8 {
    extensions : [..] *u8;
    array_add(*extensions, VK_KHR_SURFACE_EXTENSION_NAME.data);
    array_add(*extensions, VK_KHR_WIN32_SURFACE_EXTENSION_NAME.data);
    array_add(*extensions, VK_EXT_DEBUG_UTILS_EXTENSION_NAME.data);
    
    return extensions;
}