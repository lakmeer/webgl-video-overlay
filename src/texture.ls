
# Require

{ log } = require \./helpers


# In-closure state

texture-index = 0


# Texture
#
# OO wrapper around texture-related tasks

export Texture = (gl, shader, name) ->

  index   = texture-index++
  pointer = shader.uniform-at name
  texture = gl.create-texture!

  shader.set-u1i 'u_logoTexture', index
  gl.active-texture gl[ \TEXTURE + index ]
  gl.bind-texture   gl.TEXTURE_2D, texture
  gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
  gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
  gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR
  gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR

  index: index
  texture: texture

  make-active: ->
    gl.active-texture gl[ \TEXTURE + index ]
    gl.bind-texture   gl.TEXTURE_2D, texture

  upload-image: (image) ->
    @make-active!
    gl.tex-image2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image

