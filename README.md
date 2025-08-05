# OptifineRealTimePencilShader
Real Time Pencil Shader for the OptiFine Minecraft modification

## TODO

### LATER
- make/find paper normal map

### REALLY LOW PRIO
- make transparent blocks texture correctly + WATER
- make intuitive options
- torches having circular lighting when placed
- maybe a circle view distance that does not render anything beyond a certain depth?


### HIGH PRIO
- handle shadowmap noise better + rewrite shadow code
- antialiasing
- dot artifact filtring in comp shader
- handle separate AO
- shadow map weird with roses

### OPTIMIZATIONS
- refactor all code - ESPECIALLY SHADOW MAP CODE
- alpha culling





### mention in diploma

- pipeline layout: gbuffers opaque -> deferred -> gbuffers transluscent -> composite -> final
- shaders.properties, block.properties
- player feet space is locked in head and eye space is relative to camera
- gbuffersModelView is just the view matrix
- far isnt the far plane its the render distance in blocks