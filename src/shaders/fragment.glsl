precision mediump   float;
uniform   sampler2D u_image;
uniform   vec2      u_textureSize;
uniform   float     u_kernel[9];
varying   vec2      v_texCoord;

vec2 onePixel = vec2(1.0, 1.0) / u_textureSize;

vec2 pixelSize(int x, int y) {
  return onePixel * vec2(x, y);
}

// Apply convolution kernal
vec4 colorSum(float kernel[9], vec2 lookup) {
  return texture2D(u_image, lookup + pixelSize(-1, -1)) * kernel[0] +
         texture2D(u_image, lookup + pixelSize( 0, -1)) * kernel[1] +
         texture2D(u_image, lookup + pixelSize( 1, -1)) * kernel[2] +
         texture2D(u_image, lookup + pixelSize(-1,  0)) * kernel[3] +
         texture2D(u_image, lookup + pixelSize( 0,  0)) * kernel[4] +
         texture2D(u_image, lookup + pixelSize( 1,  0)) * kernel[5] +
         texture2D(u_image, lookup + pixelSize(-1,  1)) * kernel[6] +
         texture2D(u_image, lookup + pixelSize( 0,  1)) * kernel[7] +
         texture2D(u_image, lookup + pixelSize( 1,  1)) * kernel[8];
}

// Get kernel weighting
float kernelWeight (float kernel[9]) {
  float weight =
    kernel[0] + kernel[1] + kernel[2] +
    kernel[3] + kernel[4] + kernel[5] +
    kernel[6] + kernel[7] + kernel[8];
  return (weight <= 0.0) ? 1.0 : weight;
}

// Apply naive horizontal averaging blur
vec4 horizontal_average(vec2 lookup, vec2 offset) {
  return (texture2D(u_image, lookup) +
          texture2D(u_image, lookup + vec2( offset.x, 0)) +
          texture2D(u_image, lookup + vec2(-offset.x, 0))) / 3.0;
}

// Main
void main() {
   vec4  sum    = colorSum(u_kernel, v_texCoord);
   float weight = kernelWeight(u_kernel);
   gl_FragColor = vec4((sum / weight).rgb, 1.0);
}

