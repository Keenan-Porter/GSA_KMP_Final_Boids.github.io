struct Particle {
  pos: vec2f,
  vel: vec2f
};

const SIZE:f32 = 60.;

@group(0) @binding(0) var<uniform> res:   vec2f;
@group(0) @binding(1) var<storage> state_r: array<Particle>;
@group(0) @binding(2) var<storage, read_write> state_w: array<Particle>;
@group(0) @binding(3) var<storage, read_write> binSizes : array<u32>;
@group(0) @binding(4) var<storage, read_write> prefixes : array<u32>;
@group(0) @binding(5) var<uniform> audio : vec3f;
@group(0) @binding(6) var<uniform> frame: f32;

fn processBin(
  boid: Particle,
  boididx:    u32,
  boidBinIdx: u32,
  binStartingIndex: u32,
  center:   ptr<function,vec2f>, 
  keepaway: ptr<function,vec2f>, 
  vel:      ptr<function,vec2f>,
) -> u32 {
  var count = 0u;
  // make sure there's a valid bin to check
  if( boidBinIdx >= arrayLength(&binSizes) || boidBinIdx < 0 ) { return 0; }
  let binSize = binSizes[ boidBinIdx ];
  // hard limit
  let loopSize = select( binSize, 1024, binSize > 1024 );

  for( var i:u32 = 0; i < loopSize; i++ ) {
    // don't use boids' own properties in calculations
    if( boididx == i+binStartingIndex ) { continue; }

    let _boid = state_r[ binStartingIndex + i ];

    // rule 1
    *center += _boid.pos;
    
    // rule 2
    //if( length( _boid.pos - boid.pos ) < .15 ) {
      *keepaway -= ( _boid.pos - boid.pos );
    //}
   
    // rule 3
    *vel += _boid.vel;
    
    count++;
  }
  return count;
}


@compute
@workgroup_size(64,1)

fn cs(@builtin(global_invocation_id) cell:vec3u)  {

  var akeep = 0.0175;
  var aspeed = 5.0;
  var ashift = 1.0;
  if(audio[2] > 0){
    akeep = 0.01 * audio[2];
    aspeed += audio[1] * 20.;
    ashift = audio[0] * 2.;
  }

  let idx            = cell.x;
  if( idx > arrayLength(&state_r) ){ return; }
  
  var count: u32 = 0;
  var boid:Particle  = state_r[ idx ];

  var pos = boid.pos;
  // offset to one bin above
  pos.y -= select( 0., 2./SIZE, pos.y > -1+2./SIZE );
  var topidx = getBinIndex( pos ); // top
  var i:i32 = 0; // keep track of index
    
  var center:vec2f   = vec2f(0.); // rule 1
  var keepaway:vec2f = vec2f(0.); // rule 2
  var vel:vec2f      = vec2f(0.); // rule 3

  count += processBin( boid, cell.x, u32(topidx), 0, &center, &keepaway, &vel ); // top
  i += i32(SIZE) - 1;
  count += processBin( boid, cell.x, u32(i), prefixes[i+1], &center, &keepaway, &vel ); // left
  i++;
  count += processBin( boid, cell.x, u32(i), prefixes[i+1], &center, &keepaway, &vel ); // center
  i++;
  count += processBin( boid, cell.x, u32(i), prefixes[i+1], &center, &keepaway, &vel ); // right
  i += i32(SIZE) - 1;
  count += processBin( boid, cell.x, u32(i), prefixes[i+1], &center, &keepaway, &vel ); // bottom 

  // apply effects of rule 1
  center = select( center, center/f32(count), count != 0 ); 
  boid.vel += (center-boid.pos);

  // apply effects of rule 2
  boid.vel += keepaway * akeep;

  // apply effects of rule 3
  vel = select( vel, vel/f32(count), count != 0 ); 
  boid.vel += vel * .01;

  // move towards center so boids stay on screen
  boid.vel += (vec2f(0.,0.) - boid.pos);

  // limit speed
  if( length( boid.vel ) > 10. ) {
    boid.vel = (boid.vel / length(boid.vel)) * aspeed ;
  }
   
  // boundaries
  if(boid.pos.y >= 1. ) { 
    boid.pos.y = -1.;
    boid.vel.y /= 2.; 
  }
  if(boid.pos.y <= -1. ) { 
    boid.pos.y = 1.;
    boid.vel.y /= 2.; 
  }
  if( boid.pos.x >= 1. ) {
    boid.pos.x = -1.;
    boid.vel.x /= 2.;
  }
  if( boid.pos.x <= -1. ) {
    boid.pos.x = 1.;
    boid.vel.x /= 2.;
  }

  if (frame%60 == 0){
    boid.vel.x += ashift;
  }

  // calculate next position
  boid.pos = boid.pos + (2. / res) * boid.vel;

  state_w[ idx ] = boid;
}

fn getBinIndex(position : vec2f) -> i32 {
  // position is -1,1, offset by one and scale by half the bin size
  let binxy = vec2i( 
    i32( (1+position.x) * SIZE/2 ),
    i32( (1+position.y) * SIZE/2 ) 
  );

  return binxy.y * i32(SIZE) + binxy.x;
}