#version 460

layout(location = 0) in vec3 frag_color;
layout(location = 1) in vec2 texture_coords;
layout(location = 0) out vec4 out_color;

layout(set = 1, binding = 0) uniform sampler2D texture_sampler;

void main() {
  vec4 sampled = vec4(1.0, 1.0, 1.0, texture(texture_sampler, texture_coords).r);
  out_color = vec4(frag_color, 1.0) * sampled;
}
