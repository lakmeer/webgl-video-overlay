
export log = -> console.log.apply console, &; &0

export raf = request-animation-frame

export random = -> Math.random! * it

export rand-int = Math.floor . random

