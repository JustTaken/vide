#version 460

layout(location = 0) out vec3 frag_color;
layout(location = 1) out vec2 frag_texture_coords;

layout(location = 0) in vec2 texture_coords;

layout(push_constant) uniform InstanceData {
  vec2 position;
} instance;

vec2[4] vertices = {{-1.0, -1.0}, {1.0, -1.0}, {-1.0, 1.0}, {1.0, 1.0}};

layout(set = 0, binding = 0) uniform UniformGlobalObject {
  float window_ratio;
  float scale;
  float font_ratio;
} ugo;

void main() {
  vec2 p = vertices[gl_VertexIndex].xy + instance.position;
  vec2 vertex_position = ugo.scale * vec2(p.x * ugo.window_ratio * ugo.font_ratio, p.y) + vec2(-1.0, -1.0);

  gl_Position = vec4(vertex_position, 0.0, 1.0);

  frag_color = vec3(1.0);
  frag_texture_coords = texture_coords;
}
