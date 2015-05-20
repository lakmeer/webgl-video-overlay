
export Canvas = (width, height) ->
  canvas = document.create-element \canvas
  canvas.width  = width
  canvas.height = height

  gl = canvas.get-context \experimental-webgl

  document.body.append-child canvas

  gl: gl
  canvas: canvas
  context: gl
  width: width
  height: height

  render: ->
    gl.draw-arrays gl.TRIANGLES, 0, 6

