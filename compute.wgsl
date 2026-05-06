@group(0) @binding(0) var<uniform> res: vec2f;
@group(0) @binding(1) var<uniform> frame : f32;
@group(0) @binding(2) var<uniform> time: f32;
@group(0) @binding(3) var<uniform> aDisp: f32;
@group(0) @binding(4) var<uniform> bDisp: f32;
@group(0) @binding(5) var<uniform> feed: f32;
@group(0) @binding(6) var<uniform> kill: f32;
@group(0) @binding(7) var<uniform> leftDiff: f32;
@group(0) @binding(8) var<uniform> rightDiff: f32;
@group(0) @binding(9) var<uniform> topDiff: f32;
@group(0) @binding(10) var<uniform> topleftDiff: f32;
@group(0) @binding(11) var<uniform> toprightDiff: f32;
@group(0) @binding(12) var<storage> statein: array<f32>;
@group(0) @binding(13) var<storage, read_write> stateout: array<f32>;

fn index( x:i32, y:i32 ) -> u32 {
  let _res = vec2i(res);
  return u32( (y % _res.y) * _res.x + ( x % _res.x ) ) * 2;
}

@compute
@workgroup_size(8,8)
fn cs( @builtin(global_invocation_id) _cell:vec3u ) {
  let cell = vec3i(_cell);

  let a = statein[index(cell.x, cell.y)];
  let b = statein[index(cell.x, cell.y) + 1];

  let da = aDisp;
  let db = bDisp;

  let feed = feed;
  let kill = kill;
  let delta_time = time;

  let i = index(cell.x, cell.y);
  var la = statein[i] * -1.0;
  var lb = statein[i + 1] * -1.0;

  let lw = leftDiff;
  let rw = rightDiff;
  let tw = topDiff;
  let bw = topDiff;
  let ltw = topleftDiff;
  let rtw = toprightDiff;
  let lbw = topleftDiff;
  let rbw = toprightDiff;

  la += statein[ index(cell.x + 1, cell.y + 1) ] * rbw +
                        statein[ index(cell.x + 1, cell.y)     ] * rw +
                        statein[ index(cell.x + 1, cell.y - 1) ] * rtw +
                        statein[ index(cell.x, cell.y - 1)     ] * tw +
                        statein[ index(cell.x - 1, cell.y - 1) ] * ltw +
                        statein[ index(cell.x - 1, cell.y)     ] * lw +
                        statein[ index(cell.x - 1, cell.y + 1) ] * lbw +
                        statein[ index(cell.x, cell.y + 1)     ] * bw;
  
  lb += statein[ index(cell.x + 1, cell.y + 1) + 1 ] * rbw +
                        statein[ index(cell.x + 1, cell.y) + 1     ] * rw +
                        statein[ index(cell.x + 1, cell.y - 1) + 1 ] * rtw +
                        statein[ index(cell.x, cell.y - 1) + 1     ] * tw +
                        statein[ index(cell.x - 1, cell.y - 1) + 1 ] * ltw +
                        statein[ index(cell.x - 1, cell.y) + 1     ] * lw +
                        statein[ index(cell.x - 1, cell.y + 1) + 1 ] * lbw +
                        statein[ index(cell.x, cell.y + 1) + 1     ] * bw;

  let na = a + ((da * la) - (a * b * b) + (feed * (1.0 - a))) * delta_time;
  let nb = b + ((db * lb) + (a * b * b) - ((kill + feed) * b)) * delta_time;
  stateout[i] = na;
  stateout[i + 1] = nb;
}