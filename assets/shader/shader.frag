#version 460

layout(location = 0) in vec3 frag_color;
layout(location = 1) in vec2 texture_coords;
layout(location = 0) out vec4 out_color;

layout(set = 1, binding = 0) uniform sampler2D texture_sampler;

void main() {
  out_color = vec4(frag_color, texture(texture_sampler, texture_coords).r);
  // vec4 sampled = vec4(texture(texture_sampler, texture_coords).r, 0.0, 0.0, 1.0);
  // out_color = vec4(frag_color, 1.0) * sampled;
}
