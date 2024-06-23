#version 460

layout(location = 0) out vec3 frag_color;
layout(location = 1) out vec2 frag_texture_coords;

layout(location = 0) in vec2 texture_coords;

layout(push_constant) uniform InstanceData {
  vec2 position;
} instance;

vec2[4] vertices = {{-1.0, -1.0}, {1.0, -1.0}, {-1.0, 1.0}, {1.0, 1.0}};

layout(set = 0, binding = 0) uniform UniformGlobalObject {
  float ratio;
  float scale;
  float x_offset;
  float y_offset;
  float x_ratio;
} ugo;

void main() {
  vec2 p = vertices[gl_VertexIndex].xy + instance.position;
  vec2 vertex_position = ugo.scale * vec2(p.x * ugo.ratio * ugo.x_ratio, p.y) + vec2(ugo.x_offset, ugo.y_offset);

  gl_Position = vec4(vertex_position, 0.0, 1.0);

  frag_color = vec3(1.0);
  frag_texture_coords = texture_coords;
}
