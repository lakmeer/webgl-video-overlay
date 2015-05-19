
#
# Require
#

require! \fs
require! \./convolution


#
# General Helpers
#

log = -> console.log.apply console, &; &0

raf = request-animation-frame

random = -> Math.random! * it

rand-int = Math.floor . random

load-image = (src, λ) ->
  i = new Image
  i.onload = -> λ this
  i.src = src

render-svg = (img, size) ->
  canvas = document.create-element \canvas
  canvas.width = size; canvas.height = size
  ctx = canvas.get-context \2d
  ctx.draw-image img, 0, 0, size, size
  canvas

#
# GL Helpers
#

load-shader = (gl, source, type, opt_errorCallback) ->
  shader = gl.createShader type
  gl.shader-source shader, source
  gl.compileShader shader
  compiled = gl.getShaderParameter shader, gl.COMPILE_STATUS

  # Throw any errors
  if not compiled
    lastError = gl.getShaderInfoLog shader
    throw "*** Error compiling shader '" + shader + "':" + lastError
    gl.deleteShader shader
    return null

  # Return shader
  return shader


create-program = (gl, shaders) ->
  program = gl.createProgram!
  shaders.map -> gl.attachShader program, it
  gl.link-program program

  # Throw any errors
  if not gl.getProgramParameter program, gl.LINK_STATUS
    lastError = gl.getProgramInfoLog program
    throw "Error in program linking:" + lastError
    gl.deleteProgram program
    return null

  return program


#
# Shaders
#

vertex-shader   = fs.read-file-sync \src/shaders/vertex.glsl
fragment-shader = fs.read-file-sync \src/shaders/fragment.glsl


#
# Program index
#

set-rectangle = (gl, x, y, w, h) ->
  xx = x + w; yy = y + h
  vx = new Float32Array [ x, y, xx, y, x, yy, x, yy, xx, y, xx, yy ]
  gl.buffer-data gl.ARRAY_BUFFER, vx, gl.STATIC_DRAW

create-texture = (gl) ->
  texture = gl.create-texture!
  gl.bind-texture gl.TEXTURE_2D, texture
  gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
  gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
  gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST
  gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST

set-framebuffer = (gl, uniform-pointer, fbo, width, height) ->
  gl.bind-framebuffer gl.FRAMEBUFFER, fbo
  gl.uniform2f uniform-pointer, width, height
  gl.viewport 0, 0, width, height

draw-with-kernel = (gl, uniform-pointer, kernel) ->
  gl.uniform1fv uniform-pointer, kernel
  gl.draw-arrays gl.TRIANGLES, 0, 6


# Create video

video = document.create-element \video
video.preload = \auto
video.muted = yes
video.src = \chaos.webm
video-done = -> video.seek 0; video.play!
video.add-event-listener \canplaythrough, video~play, on
video.add-event-listener \ended, video-done, on


# Load images

img-bg <- load-image \tree.jpg
img-svg <- load-image \aviary.svg

img-logo = render-svg img-svg, 2048

# Get A WebGL context
canvas = document.create-element \canvas
canvas <<< { width: 512, height: 512 }
gl = canvas.get-context \experimental-webgl

# Commit canvas to DOM
document.body.append-child canvas

# Setup a GLSL program
vertex   = load-shader gl, vertex-shader,   gl.VERTEX_SHADER
fragment = load-shader gl, fragment-shader, gl.FRAGMENT_SHADER
program  = create-program gl, [ vertex, fragment ]
gl.use-program program

# Look up locations of shader parameters
color-location        = gl.get-uniform-location program, 'u_color'
tex-coord-location    = gl.get-attrib-location  program, 'a_texCoord'
position-location     = gl.get-attrib-location  program, 'a_position'
resolution-location   = gl.get-uniform-location program, 'u_resolution'
texture-size-location = gl.get-uniform-location program, 'u_screenSize'
kernel-location       = gl.get-uniform-location program, 'u_kernel[0]'
big-kernel-location   = gl.get-uniform-location program, 'u_bigKernel[0]'
flip-y-location       = gl.get-uniform-location program, 'u_flipY'
blur-radius-location  = gl.get-uniform-location program, 'u_blurRadius'
nudge-location        = gl.get-uniform-location program, 'u_nudge'


#
# Set Uniforms
#

# Supply canvas resolution
gl.uniform2f resolution-location, canvas.width, canvas.height
gl.uniform2f texture-size-location, img-bg.width, img-bg.height
gl.uniform1f flip-y-location, -1
gl.uniform1f blur-radius-location, 5

# Set convolution options
gl.uniform1fv kernel-location, convolution.gaussianBlur3
gl.uniform1fv big-kernel-location, convolution.box25


#
# Create textures
#

# Background
texture-location0 = gl.get-uniform-location program, 'u_bgTexture'
bg-texture = gl.create-texture!
gl.active-texture gl.TEXTURE0
gl.uniform1i texture-location0, 0
gl.bind-texture gl.TEXTURE_2D, bg-texture
gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR
gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
gl.tex-image2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, img-bg

# Logo Mask
texture-location1 = gl.get-uniform-location program, 'u_logoTexture'
gl.active-texture gl.TEXTURE1
gl.uniform1i texture-location1, 1
logo-texture = gl.create-texture!
gl.bind-texture gl.TEXTURE_2D, logo-texture
gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR
gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
gl.tex-image2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, img-logo

# Create on-the-fly texture updater
update-bg = (source) ->
  gl.active-texture gl.TEXTURE0
  gl.bind-texture gl.TEXTURE_2D, bg-texture
  gl.tex-image2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, source



#
# Prepare vertex buffers
#

# Prepare texture coordinates
tex-coord-buffer  = gl.create-buffer!
gl.bind-buffer gl.ARRAY_BUFFER, tex-coord-buffer
gl.buffer-data gl.ARRAY_BUFFER, (new Float32Array [ 0 0 1 0 0 1 0 1 1 0 1 1 ]), gl.STATIC_DRAW
gl.enable-vertex-attrib-array tex-coord-location
gl.vertex-attrib-pointer tex-coord-location, 2, gl.FLOAT, false, 0, 0

# Prepare  Bind textures
buffer = gl.create-buffer!
gl.bind-buffer gl.ARRAY_BUFFER, buffer
gl.enable-vertex-attrib-array position-location
gl.vertex-attrib-pointer position-location, 2, gl.FLOAT, false, 0, 0
set-rectangle gl, 0, 0, canvas.width, canvas.height


# Frame Loop
t     = Date.now!
time  = 0
stop  = no
frame = ->
  if not stop then raf frame
  Δt = ((now = Date.now!) - t) / 500
  time += Δt
  t := now
  x  = 0.5 + Math.sin time
  y  = 0.5 + Math.cos time
  k  = Math.floor(time) % 4
  #set-rectangle gl, x, y, canvas.width, canvas.height
  #gl.uniform2f nudge-location, x, y
  #update-bg video
  gl.draw-arrays gl.TRIANGLES, 0, 6

frame!

