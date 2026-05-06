struct Particle {
  pos: vec2f,
  vel: vec2f
};

const GRID_SIZE:i32 = 60;

@group(0) @binding(0) var<storage> particles_in  : array<Particle>;
@group(0) @binding(1) var<storage, read_write> particles_out : array<Particle>;
@group(0) @binding(2) var<storage, read_write> binSizes : array<u32>;

// current count (per-invocation) of bin, which we increment when we place particle
@group(0) @binding(3) var<storage, read_write> binCurrentCount : array<atomic<u32>>;
@group(0) @binding(4) var<storage, read_write> prefixes : array<u32>;

@compute @workgroup_size(64,1,1)
fn cs(@builtin(global_invocation_id) id : vec3u) {
  if (id.x >= arrayLength(&particles_in)) { return; }

  // read the particle data
  let particle = particles_in[id.x];

  // compute the linearized bin index
  let binIndex = getBinIndex( particle.pos );

  // reduce bin sizes up to bin index
  var indexSum: u32 = prefixes[ binIndex + 1 ];

  // atomic add to current bin size
  let outputIndex = atomicAdd(&binCurrentCount[binIndex], 1u) + indexSum;

  // assign to output particle array
  particles_out[ outputIndex ] = particle;
}

fn getBinIndex(position : vec2f) -> i32 {
  // position is -1,1, offset by one and scale by half the bin size
  let binxy = vec2i( 
    i32( (1+position.x) * f32(GRID_SIZE/2) ),
    i32( (1+position.y) * f32(GRID_SIZE/2) ) 
  );

  return binxy.y * GRID_SIZE + binxy.x;
}
