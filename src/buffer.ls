
# Require

{ log } = require \./helpers


# Buffer
#
# OO wrapper around buffer-related tasks

export GLBuffer = (gl, pointer, raw) ->

  buffer = gl.create-buffer!
  data   = new Float32Array raw

  gl.bind-buffer gl.ARRAY_BUFFER, buffer
  gl.buffer-data gl.ARRAY_BUFFER, data, gl.STATIC_DRAW
  gl.enable-vertex-attrib-array pointer
  gl.vertex-attrib-pointer pointer, 2, gl.FLOAT, false, 0, 0

  buffer: buffer

  make-active: ->
    gl.bind-buffer gl.ARRAY_BUFFER, buffer

  upload-data: (raw) ->
    @make-active!
    data = new Float32Array raw
    gl.buffer-data gl.ARRAY_BUFFER, data, gl.STATIC_DRAW

