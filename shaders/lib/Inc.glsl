#include "Definitions.glsl"

#if defined(VERTEX_SHADER) || defined(FRAGMENT_SHADER)    
    #include "Uniforms.glsl"
    #include "Geometry.glsl"
    #include "Common.glsl"
    #include "Shadows.glsl"
    #include "MaterialHandling.glsl"
    #include "ContourDetection.glsl"
    #include "ContourDisplacing.glsl"
    #include "CrosshatchShading.glsl"
#endif  

#ifdef COMPUTE_SHADER 
    #include "Uniforms.glsl"
#endif