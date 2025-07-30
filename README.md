# OptifineRealTimePencilShader
Real Time Pencil Shader for the OptiFine Minecraft modification

## TODO

### LATER
- make/find paper normal map

### REALLY LOW PRIO
- make transparent blocks texture correctly
- make intuitive options
- torches having circular lighting when placed
- white shadow map distortion artifacts


### QOL
- implement ambient occlusion

### RESONABLY DONE - maybe good? think about later

### HIGH PRIO
- fix aliasing on contours and artifacs from sky - check official zbuffer for the latter
- rewrite blend functions for crosshatching

### OPTIMIZATIONS
- refactor all code - ESPECIALLY SHADOW MAP CODE
- combine comp3 and comp2
- reduce buffers by calculating certain things on the fly - UV (discard) normals and positions all form model space
