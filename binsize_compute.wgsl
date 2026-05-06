struct Particle {
  pos: vec2f,
  vel: vec2f
};

const GRID_SIZE:i32 = 60;

@group(0) @binding(0) var<storage> particles : array<Particle>;
@group(0) @binding(1) var<storage, read_write> particles2: array<Particle>;
@group(0) @binding(2) var<storage, read_write> binSize : array<atomic<u32>>;

@compute @workgroup_size(64,1,1)
fn cs(@builtin(global_invocation_id) id : vec3u) {
  if (id.x >= arrayLength(&particles)) { return; }

  // Read the particle data
  let particle = particles[id.x];

  // Compute the linearized bin index
  let binIndex = getBinIndex( particle.pos );

  // Increment the size of the bin
  atomicAdd(&binSize[binIndex], 1u);
}

fn getBinIndex(position : vec2f) -> i32 {
  // position is -1,1, offset by one and scale by half the bin size
  let binxy = vec2i( 
    i32( (1+position.x) * f32(GRID_SIZE/2) ),
    i32( (1+position.y) * f32(GRID_SIZE/2) ) 
  );

  return binxy.y * GRID_SIZE + binxy.x;
}