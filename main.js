import { default as seagulls } from './seagulls.js'
import { default as Audio    } from './audio.js'

const sg = await seagulls.init(),
      render_shader  = await seagulls.import( './frag.wgsl' ),
      compute_shader = await seagulls.import( './compute.wgsl' ),
      prefix_shader = await seagulls.import( './prefix_compute.wgsl' ),
      place_shader = await seagulls.import( './place_compute.wgsl' )

// Audio for interactivity
document.body.onclick = e => Audio.start()
const fft = sg.uniform( [0,0,0] )

const NUM_PARTICLES = 65536, 
      NUM_PROPERTIES = 4,
      GRID_SIZE = 60,
      WORKGROUP_SIZE = 4, 
      state = new Float32Array( NUM_PARTICLES * NUM_PROPERTIES )

for( let i = 0; i < NUM_PARTICLES * NUM_PROPERTIES; i+= NUM_PROPERTIES ) {
  state[ i ] = -1 + Math.random() * 2
  state[ i + 1 ] = -1 + Math.random() * 2
  state[ i + 2 ] = Math.random() * 10
}

const state_b = sg.buffer( state ),
      frame_u = sg.uniform( 0 ),
      res_u   = sg.uniform([ sg.width, sg.height ]) 

const usage = GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC | GPUBufferUsage.COPY_DST
const sizes_b  = sg.buffer( new Float32Array(GRID_SIZE*GRID_SIZE), '', usage )
const binsize_shader = await seagulls.import( './binsize_compute.wgsl' )
const state_b2 = sg.buffer( state )

const render = await sg.render({
  shader: render_shader,
  vertices:seagulls.constants.shapes.triangle,
  data: [
    frame_u,
    res_u,
    state_b,
    fft
  ],
  onframe() { frame_u.value++
              fft.value = [Audio.low, Audio.mid, Audio.high]
   },
  count: NUM_PARTICLES,
  blend: true
})

const dc = Math.ceil( NUM_PARTICLES / 64 )
const prefix_b = sg.buffer( new Float32Array(GRID_SIZE*GRID_SIZE + 1), '', usage )
const prefix = sg.compute({
  shader: prefix_shader,
  data:[
    sizes_b,
    prefix_b
  ],
  dispatchCount:[1,1,1]
})

const count_b = sg.buffer( new Float32Array( GRID_SIZE*GRID_SIZE ) )
const place = sg.compute({
  shader: place_shader,
  data:[
    sg.pingpong(state_b2,state_b),
    sizes_b,
    count_b,
    prefix_b
  ],

  dispatchCount:[NUM_PARTICLES / (WORKGROUP_SIZE * WORKGROUP_SIZE),1,1]
})

const sizes = sg.compute({
  shader: binsize_shader,
  data:[
    sg.pingpong(state_b,state_b2),
    sizes_b
  ],
  onframe() { sizes_b.clear() },
  dispatchCount:[NUM_PARTICLES / (WORKGROUP_SIZE * WORKGROUP_SIZE),1,1]
})

const compute = sg.compute({
  shader: compute_shader,
  data:[
    res_u,
    sg.pingpong(state_b2, state_b),
    sizes_b,
    prefix_b,
    fft,
    frame_u
  ],
  onframe() { frame_u.value++
              fft.value = [Audio.low, Audio.mid, Audio.high]
   },
  dispatchCount:[NUM_PARTICLES / (WORKGROUP_SIZE * WORKGROUP_SIZE),1,1],
})

sg.run( sizes, prefix, place, compute, render )
// await sg.once( sizes, compute, render )
// console.log( await sizes_b.read( null, 0, Uint32Array ))