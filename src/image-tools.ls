
export load-image = (src, λ) ->
  i = new Image
  i.onload = -> λ this
  i.src = src

export render-svg = (img, size) ->
  canvas = document.create-element \canvas
  canvas.width = size; canvas.height = size
  ctx = canvas.get-context \2d
  ctx.draw-image img, 0, 0, size, size
  canvas

