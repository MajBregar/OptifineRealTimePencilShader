

#if defined(VERTEX_SHADER) || defined(FRAGMENT_SHADER)    
    #include "Uniforms.glsl"
    #include "Definitions.glsl"
    #include "Geometry.glsl"
    #include "Common.glsl"
    #include "Shadows.glsl"
    #include "BlockHandling.glsl"
#endif

#ifdef COMPUTE_SHADER 
    #include "Definitions.glsl"
    #include "Uniforms.glsl"
#endif