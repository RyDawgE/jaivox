// opengl

RenderHandle :: struct {
    window                     : *void                    = null;
    instance                   : *void              = null;
}

initialize_render :: (render_handle : *RenderHandle) {}
cleanup_render :: () {}
draw_frame :: () {}
