
#
# In-closure helpers
#

# Load Shader
#
# Compiles a shader program of the given type, using the given source code

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


# Create Program
#
# Combines a vertex and fragment shader and can fetch pointers into the result

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


# Shader Program
#
# Object-oriented wrapper for shader related tasks

export ShaderProgram = (gl, vtx, frg) ->
  vertex   = load-shader gl, vtx, gl.VERTEX_SHADER
  fragment = load-shader gl, frg, gl.FRAGMENT_SHADER
  program  = create-program gl, [ vertex, fragment ]
  gl.use-program program

  uniform-at : (name) -> gl.get-uniform-location program, name
  attrib-at  : (name) -> gl.get-attrib-location  program, name
  set-u1i    : (u, a) -> gl.uniform1i  (@uniform-at u), a
  set-u1f    : (u, a) -> gl.uniform1f  (@uniform-at u), a
  set-u1fv   : (u, a) -> gl.uniform1fv (@uniform-at u), a
  set-u2f    : (u,a,b) -> gl.uniform2f (@uniform-at u), a, b

