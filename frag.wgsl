@group(0) @binding(0) var<uniform> res:   vec2f;
@group(0) @binding(1) var<storage> state: array<f32>;

@fragment 
fn fs( @builtin(position) pos : vec4f ) -> @location(0) vec4f {
  let idx : u32 = u32( pos.y * res.x + pos.x ) * 2;
  let a = state[ idx ];
  let b = state[ idx + 1];
  return vec4f( a - b, a - b, a - b, 1.);
}