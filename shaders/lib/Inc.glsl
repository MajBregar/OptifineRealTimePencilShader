#include "Definitions.glsl"
#include "Uniforms.glsl"

#if defined(VERTEX_SHADER) || defined(FRAGMENT_SHADER)    
    #include "Common.glsl"
    #include "Geometry.glsl"
    #include "Mipmaps.glsl"
    #include "Shadows.glsl"
    #include "Lighting.glsl"
    #include "MaterialHandling.glsl"
    #include "ContourDetection.glsl"
    #include "ContourDisplacing.glsl"
    #include "CrosshatchShading.glsl"
#endif  

#ifdef COMPUTE_SHADER 
#endif