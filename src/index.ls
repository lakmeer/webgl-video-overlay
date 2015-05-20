
#
# Require
#

require! \fs

{ id, log, raf, random, rand-int } = require \./helpers
{ load-image, render-svg } = require \./image-tools

vertex-shader   = fs.read-file-sync \src/shaders/vertex.glsl
fragment-shader = fs.read-file-sync \src/shaders/fragment.glsl

{ Video } = require \./video
{ Canvas } = require \./canvas
{ Texture } = require \./texture
{ GLBuffer } = require \./buffer
{ FrameDriver } = require \./frame-driver
{ ShaderProgram } = require \./shader-program

#
# Other Helpers
#

set-framebuffer = (gl, uniform-pointer, fbo, width, height) ->
  gl.bind-framebuffer gl.FRAMEBUFFER, fbo
  gl.uniform2f uniform-pointer, width, height
  gl.viewport 0, 0, width, height

screen-space-quad = (x, y, w, h) ->
  xx = x + w; yy = y + h
  [ x, y, xx, y, x, yy, x, yy, xx, y, xx, yy ]


#
# Preload assets
#

img-bg  <- load-image \tree.jpg
img-svg <- load-image \aviary.svg

img-logo = render-svg img-svg, 2048

#video = Video \/chaos.webm


#
# Program index
#

# Create canvas and context
canvas = Canvas 1024, 650
gl = canvas.context

# Compile shader program
shader = ShaderProgram canvas.gl, vertex-shader, fragment-shader
shader.set-u2f  'u_resolution', canvas.width, canvas.height
shader.set-u2f  'u_screenSize', img-bg.width, img-bg.height
shader.set-u1f  'u_flipY', -1
shader.set-u1f  'u_blurRadius', 5

# Create textures
bg-texture = Texture canvas.gl, shader, 'u_bgTexture'
bg-texture.upload-image img-bg
logo-texture = Texture canvas.gl, shader, 'u_logoTexture'
logo-texture.upload-image img-logo

# Prepare buffers
texture-coords = GLBuffer canvas.gl, (shader.attrib-at 'a_texCoord'), [ 0 0 1 0 0 1 0 1 1 0 1 1 ]
quad-vertices  = GLBuffer canvas.gl, (shader.attrib-at 'a_position'), screen-space-quad 0, 0, canvas.width, canvas.height

# Frame Loop
frame-driver = FrameDriver (Δt, time) ->
  x = 0.5 + Math.sin time
  y = 0.5 + Math.cos time
  k = Math.floor(time) % 4

  #gl.uniform2f nudge-location, x, y
  #bg-texture.upload-image video
  gl.draw-arrays gl.TRIANGLES, 0, 6

canvas.render!

