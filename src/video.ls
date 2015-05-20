
export Video = (src) ->
  video = document.create-element \video
  video.preload = \auto
  video.muted = yes
  video.add-event-listener \canplaythrough, video~play, on
  video.add-event-listener \ended, (-> video.seek 0; video.play!), on
  video.src = src
  return video

