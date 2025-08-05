/*
const int colortex0Format = RGB16;
const int colortex1Format = RGB16F;
const int colortex2Format = RGB32F;
const int colortex3Format = RG16;
const int colortex4Format = RGBA16;
const int colortex5Format = R32UI;
const int colortex6Format = RG16;
const int colortex7Format = RGB16;
const int colortex8Format = RGB16;
const int colortex9Format = RG16F;
const int colortex10Format = R32F;
const int colortex11Format = RGB16;
*/

const int shadowMapResolution = 2048;
const int noiseTextureResolution = 128;
const float sunPathRotation = 45.0;
const float eyeBrightnessHalflife = 1.0;
const vec4 colortex5ClearColor = vec4(-3.4028235e+38,0.,0.,0.); //reset int depth compute buffer to 0xFF7FFFFF 
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;


uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex11;

uniform sampler2D texture;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;

uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
uniform vec3 chunkOffset;
uniform vec3 sunPosition;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform vec3 cameraPosition;
uniform vec3 upPosition;
uniform int entityId;
uniform int heldItemId;
uniform int worldTime;
uniform float aspectRatio;
uniform float sunAngle;
uniform int frameCounter;


uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat3 normalMatrix;
uniform mat4 textureMatrix;



