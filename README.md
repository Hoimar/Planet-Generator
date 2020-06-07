# Planet-Generator

This is a simple, procedural planet generator based on different, layered noise functions with dynamic LOD (terrain chunks), written in GDScript.


# Credits
 * (this amazing tutorial)[https://www.youtube.com/watch?v=QN39W020LqU&index=2&t=0s&list=PLFt_AvWsXl0cONs3T0By4puYy6GM22ko8] for creating procedurally generated planets by Sebastian Lague
 * (atmosphere shader)[https://github.com/Dimev/Realistic-Atmosphere-Godot-and-UE4] by Dimas Leenman, Shared under the MIT license, slightly adapted


# TODO
 * optimize TerrainFace generation, find hotspots/bottlenecks, prioritize threads, limit max. number of threads
 * multiple noise maps: one for height, one for biomes and/or one for colors, etc.
 * preview texture for NoiseGenerator resource
 * fix seams between TerrainFaces
 * cloud layer around planets
 * larger scale to allow for finer detail, needs adjustment or replacement of atmosphere shader
 * better terrain shaders with textures, noise border instead of straight one
 * adjustable sea level which will adjust the color gradient and the water mesh
 * vegetation, rocks, etc.
