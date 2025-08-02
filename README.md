# OptifineRealTimePencilShader
Real Time Pencil Shader for the OptiFine Minecraft modification

## TODO

### LATER
- make/find paper normal map

### REALLY LOW PRIO
- make transparent blocks texture correctly
- make intuitive options
- torches having circular lighting when placed
- maybe a circle view distance that does not render anything beyond a certain depth?


### QOL
- make the falloff code right, its pow(depth, x) not pow(1-depth, x)

### RESONABLY DONE - maybe good? think about later

### HIGH PRIO
- fix aliasing on contours and artifacs from sky - check official zbuffer for the latter
- refactor code especially hand handling


### OPTIMIZATIONS
- refactor all code - ESPECIALLY SHADOW MAP CODE
- alpha culling
















### mention in diploma

- pipeline layout: gbuffers opaque -> deferred -> gbuffers transluscent -> composite -> final
- shaders.properties, block.properties
