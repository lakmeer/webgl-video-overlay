
# Require

{ log, raf } = require \./helpers


# Frame Driver

export FrameDriver = (λ) ->
  t     = Date.now!
  time  = 0
  stop  = yes

  frame = ->
    if not stop then raf frame
    Δt = ((now = Date.now!) - t) / 500
    time += Δt
    λ Δt, time
    t := now

  start: -> stop := no; frame!
  stop: -> stop := yes

