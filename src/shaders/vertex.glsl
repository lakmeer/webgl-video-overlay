
attribute vec2  a_texCoord;
attribute vec2  a_position;
uniform   vec2  u_resolution;
uniform   float u_flipY;
varying   vec2  v_texCoord;

vec2 clipspace = (a_position / u_resolution) * 2.0 - 1.0;
vec2 flipyaxis = vec2(1, u_flipY);

void main() {
  gl_Position = vec4(clipspace * flipyaxis, 0, 1);
  v_texCoord  = a_texCoord;
}

