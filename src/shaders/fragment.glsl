precision mediump   float;
uniform   sampler2D u_bgTexture;
uniform   sampler2D u_logoTexture;
uniform   sampler2D u_extraTexture;
uniform   vec2      u_screenSize;
uniform   vec2      u_nudge;
uniform   float     u_kernel[9];
uniform   float     u_bigKernel[25];
uniform   float     u_blurRadius;
varying   vec2      v_texCoord;


// Const

vec2 nudge = u_nudge * 0.03;
vec2 onePixel = vec2(1.0, 1.0) / u_screenSize;

float ov = 0.1;
vec4 overlay = vec4(ov, ov, ov, 1);

vec2 convSize(int x, int y) {
  return u_blurRadius * onePixel * vec2(x, y);
}

// 9-hit convolution
vec4 convolve9(sampler2D image, float kernel[9], vec2 lookup) {
  vec4 total = vec4(0,0,0,0);
  for (int y = 0; y < 3; y++) {
    for (int x = 0; x < 3; x++) {
      total += texture2D(image, lookup + convSize(-1 + x, -1 + y)) * kernel[x+y*3];
    }
  }
  return total;
}

// 25-hit convolution
vec4 convolve25(sampler2D image, float kernel[25], vec2 lookup) {
  vec4 total = vec4(0,0,0,0);
  for (int y = 0; y < 5; y++) {
    for (int x = 0; x < 5; x++) {
      total += texture2D(image, lookup + convSize(-2+x, -2+y)) * kernel[x+y*x];
    }
  }
  return total;
}

// Get kernel weighting
float kernelWeight9 (float kernel[9]) {
  float weight = 0.0;
  for (int i = 0; i < 9; i++) {
    weight += kernel[i];
  }
  return (weight <= 0.0) ? 1.0 : weight;
}

// Get kernel weighting
float kernelWeight25 (float kernel[25]) {
  float weight = 0.0;
  for (int i = 0; i < 25; i++) {
    weight += kernel[i];
  }
  return (weight <= 0.0) ? 1.0 : weight;
}

// Apply naive horizontal averaging blur
vec4 horizontal_average(sampler2D image, vec2 lookup, vec2 offset) {
  return (texture2D(image, lookup) +
          texture2D(image, lookup + vec2( offset.x, 0)) +
          texture2D(image, lookup + vec2(-offset.x, 0))) / 3.0;
}

// Invert rgba color (but leave alpha intact)
vec4 invert(vec4 color) {
  return vec4( (vec3(1, 1, 1) - color.rgb), color.a );
}


// Main
void main() {
  vec4  sum    = vec4(0,0,0,0);
  float weight = 0.0;

  if (false) {
    sum    = convolve9 (u_bgTexture, u_kernel,    v_texCoord + nudge);
    weight = kernelWeight9(u_kernel);
  } else {
    sum    = convolve25(u_bgTexture, u_bigKernel, v_texCoord + nudge);
    weight = kernelWeight25(u_bigKernel);
  }

  vec4 bgBlur     = vec4((sum / weight).rgb, 1.0);
  vec4 bgColor    = texture2D(u_bgTexture, v_texCoord + nudge);
  //vec4 extraColor = texture2D(u_extraTexture, v_texCoord);
  vec4 logoColor  = texture2D(u_logoTexture, v_texCoord);

  vec4 mask       = invert(logoColor);

  gl_FragColor = mask * overlay + mask * bgBlur + logoColor * bgColor;
}

