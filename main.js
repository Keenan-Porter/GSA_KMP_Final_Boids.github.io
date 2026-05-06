import { default as seagulls } from './gulls/gulls.js'
import {Pane} from 'https://cdn.jsdelivr.net/npm/tweakpane@4.0.5/dist/tweakpane.min.js';

const sg      = await seagulls.init(),
      frag    = await seagulls.import( './frag.wgsl' ),
      compute = await seagulls.import( './compute.wgsl' ),
      render  = seagulls.constants.vertex + frag,
      size    = (window.innerWidth * window.innerHeight),
      state   = new Float32Array( size * 2 )

const pane = new Pane()
const time = {
  view: 'slider',
  label: 'time',
  min: 0.0,
  max: 1.0,
  value: 1.0
}
const timeBlade = pane.addBlade(time, 'time')
let timebuffer = sg.uniform( time.value )
timeBlade.on('change', (ev) => {
  time.value = ev.value
  timebuffer.value = ev.value
})
const adisp = {
  view: 'slider',
  label: 'A Dispersal',
  min: 0.0,
  max: 1.0,
  value: 1.0
}
const adispBlade = pane.addBlade(adisp, 'A Dispersal')
let adispbuffer = sg.uniform( adisp.value )
adispBlade.on('change', (ev) => {
  adisp.value = ev.value
  adispbuffer.value = ev.value
})
const bdisp = {
  view: 'slider',
  label: 'B Dispersal',
  min: 0.0,
  max: 1.0,
  value: 0.5
}

const bdispBlade = pane.addBlade(bdisp, 'B Dispersal')
let bdispbuffer = sg.uniform( bdisp.value )
bdispBlade.on('change', (ev) => {
  bdisp.value = ev.value
  bdispbuffer.value = ev.value
})
const feed = {
  view: 'slider',
  label: 'feed',
  min: 0.01,
  max: 0.1,
  value: 0.055
}

const feedBlade = pane.addBlade(feed, 'Feed')
let feedbuffer = sg.uniform( feed.value )
feedBlade.on('change', (ev) => {
  feed.value = ev.value
  feedbuffer.value = ev.value
})
const kill = {
  view: 'slider',
  label: 'kill',
  min: 0.045,
  max: 0.07,
  value: 0.062
}
const killBlade = pane.addBlade(kill, 'Kill')
let killbuffer = sg.uniform( kill.value )
killBlade.on('change', (ev) => {
  kill.value = ev.value
  killbuffer.value = ev.value
})

const leftDiff = {
  view: 'slider',
  label: 'left Diffusion',
  min: 0.0,
  max: 1.0,
  value: 0.2
}
const leftDiffBlade = pane.addBlade(leftDiff, 'Left Diffusion')
let leftDiffbuffer = sg.uniform( leftDiff.value )
leftDiffBlade.on('change', (ev) => {
  leftDiff.value = ev.value
  leftDiffbuffer.value = ev.value
}) 
const rightDiff = {
  view: 'slider',
  label: 'right Diffusion',
  min: 0.0,
  max: 1.0,
  value: 0.2
}
const rightDiffBlade = pane.addBlade(rightDiff, 'Right Diffusion')
let rightDiffbuffer = sg.uniform( rightDiff.value )
rightDiffBlade.on('change', (ev) => {
  rightDiff.value = ev.value
  rightDiffbuffer.value = ev.value
})
const topDiff = {
  view: 'slider',
  label: 'top Diffusion',
  min: 0.0,
  max: 1.0,
  value: 0.2
}
const topDiffBlade = pane.addBlade(topDiff, 'Top Diffusion')
let topDiffbuffer = sg.uniform( topDiff.value )
topDiffBlade.on('change', (ev) => {
  topDiff.value = ev.value
  topDiffbuffer.value = ev.value
})
const topleftDiff = {
  view: 'slider',
  label: 'top Left Diffusion',
  min: 0.0,
  max: 1.0,
  value: 0.05
}
const topleftDiffBlade = pane.addBlade(topleftDiff, 'Top Left Diffusion')
let topleftDiffbuffer = sg.uniform( topleftDiff.value )
topleftDiffBlade.on('change', (ev) => {
  topleftDiff.value = ev.value
  topleftDiffbuffer.value = ev.value
})
const toprightDiff = {
  view: 'slider',
  label: 'top right Diffusion',
  min: 0.0,
  max: 1.0,
  value: 0.05
}
const toprightDiffBlade = pane.addBlade(toprightDiff, 'Top Right Diffusion')
let toprightDiffbuffer = sg.uniform( toprightDiff.value )
toprightDiffBlade.on('change', (ev) => {
  toprightDiff.value = ev.value
  toprightDiffbuffer.value = ev.value
})



for( let i = 0; i < size; i++ ) {
  state[ i * 2 ] = 1.0
  state[(i * 2) + 1] = 0.0
}

for(let i = 475; i < 525; i++){
  for(let j = -25; j < 25; j++){
    state[(i * window.innerWidth + j) * 2 + 1] = 1.0
  } 
}

const statebuffer1 = sg.buffer( state )
const statebuffer2 = sg.buffer( state )
const res = sg.uniform([ window.innerWidth, window.innerHeight ])

let frame_u = sg.uniform(0)

const renderPass = await sg.render({
  shader: render,
  data: [
    res,
    sg.pingpong( statebuffer1, statebuffer2 )
  ]
})

const computePass = sg.compute({
  shader: compute,
  data: [ 
    res,
    frame_u,
    timebuffer,
    adispbuffer,
    bdispbuffer,
    feedbuffer,
    killbuffer,
    leftDiffbuffer,
    rightDiffbuffer,
    topDiffbuffer,
    topleftDiffbuffer,
    toprightDiffbuffer,
    sg.pingpong( statebuffer1, statebuffer2 ) ],
  onframe () { 
  frame_u.value++
  },
  dispatchCount:  [Math.round(seagulls.width / 8), Math.round(seagulls.height/8), 1],
})

sg.run( computePass, renderPass )