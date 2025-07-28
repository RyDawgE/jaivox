create_shader_objects :: () {
    //Vertex Shaders
    define_shader("SPRITE_VERT", GL_VERTEX_SHADER, "%/../src/shaders/sprite.vert");
    define_shader("WOBBLE_SPRITE_VERT", GL_VERTEX_SHADER, "%/../src/shaders/wobble_sprite.vert");

    //Fragment Shaders
    define_shader("ANIMATED_SPRITE_FRAG", GL_FRAGMENT_SHADER, "%/../src/shaders/anim_sprite.frag");
    define_shader("RAINBOW_SPRITE_FRAG", GL_FRAGMENT_SHADER, "%/../src/shaders/rainbow_sprite.frag");
    define_shader("BATTLEBG_FRAG", GL_FRAGMENT_SHADER, "%/../src/shaders/battlebg.frag");
}

// TODO, this needs to bake source into the binary just like the textures do.
