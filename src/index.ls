
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
  i.onload = λ
  i.src = src


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


# Load image
load-image \leaves.jpg, ->

  # Get A WebGL context
  canvas = document.create-element \canvas
  canvas <<< { width: 512, height: 512 }
  gl = canvas.get-context \experimental-webgl

  # Commit canvas to DOM
  document.body.append-child canvas

  # Receive image from loaded callback
  image = this

  # Setup a GLSL program
  vertex   = load-shader gl, vertex-shader,   gl.VERTEX_SHADER
  fragment = load-shader gl, fragment-shader, gl.FRAGMENT_SHADER
  program  = create-program gl, [ vertex, fragment ]
  gl.use-program program

  # Look up where the vertex data needs to go.
  color-location        = gl.get-uniform-location program, 'u_color'
  tex-coord-location    = gl.get-attrib-location  program, 'a_texCoord'
  position-location     = gl.get-attrib-location  program, 'a_position'
  resolution-location   = gl.get-uniform-location program, 'u_resolution'
  texture-size-location = gl.get-uniform-location program, 'u_textureSize'
  kernel-location       = gl.get-uniform-location program, 'u_kernel[0]'
  flip-y-location       = gl.get-uniform-location program, 'u_flipY'

  # Supply canvas resolution
  gl.uniform2f resolution-location, canvas.width, canvas.height
  gl.uniform2f texture-size-location, image.width, image.height

  # Prepare texture buffer
  tex-coord-buffer  = gl.create-buffer!
  gl.bind-buffer gl.ARRAY_BUFFER, tex-coord-buffer
  gl.buffer-data gl.ARRAY_BUFFER, (new Float32Array [ 0 0 1 0 0 1 0 1 1 0 1 1 ]), gl.STATIC_DRAW
  gl.enable-vertex-attrib-array tex-coord-location
  gl.vertex-attrib-pointer tex-coord-location, 2, gl.FLOAT, false, 0, 0

  # First state (input) texture
  input-texture = create-texture gl
  gl.tex-image2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image

  # Extra framebuffers
  kernels      = [ convolution.normal, convolution.gaussianBlur3, convolution.unsharpen, convolution.emboss ]
  textures     = []
  framebuffers = []

  # Generate two framebuffers to ping-pong each shader pass
  for i from 0 to 2
    break
    # Make texture
    textures.push texture = create-texture gl
    gl.tex-image2D gl.TEXTURE_2D, 0, gl.RGBA, 512, 512, 0, gl.RGBA, gl.UNSIGNED_BYTE, null

    # Make FBO
    framebuffers.push fbo = gl.create-framebuffer!
    gl.bind-framebuffer gl.FRAMEBUFFER, fbo
    gl.framebuffer-texture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0

  # Bind textures
  gl.bind-texture gl.TEXTURE_2D, input-texture
  gl.uniform1f flip-y-location, 1

  # Ping-pong framebuffers to render to
#  for kernel, i in kernels
#    if i is 0 then continue
#    set-framebuffer  gl, resolution-location, framebuffers[i % 2], 512, 512
#    draw-with-kernel gl, kernel-location, kernel
#    gl.bind-texture gl.TEXTURE_2D, textures[i % 2]
#

  gl.uniform1f flip-y-location, -1
  #set-framebuffer  gl, resolution-location, null, canvas.width, canvas.height

  # Convolution Kernels
  gl.uniform1fv kernel-location, convolution.box-blur
  draw-with-kernel gl, kernel-location, kernels.0

  return

  # Frame Loop
  t = Date.now!
  time = 0
  stopped = no

  frame = ->
    if not stopped then raf frame

    Δt = ((now = Date.now!) - t) / 1000
    time += Δt
    t := now
    x  = 100 + 100 * Math.sin time
    y  = 100 + 100 * Math.cos time

    buffer = gl.create-buffer!
    gl.bind-buffer gl.ARRAY_BUFFER, buffer
    gl.enable-vertex-attrib-array position-location
    gl.vertex-attrib-pointer position-location, 2, gl.FLOAT, false, 0, 0
    set-rectangle gl, x, y, 300, 300

    gl.draw-arrays gl.TRIANGLES, 0, 6

  frame!

