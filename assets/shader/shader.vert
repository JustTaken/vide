#version 460

layout(location = 0) out vec3 frag_color;
layout(location = 1) out vec2 frag_texture_coords;

layout(location = 0) in uint index;
// layout(location = 1) in uvec2 position;
layout(location = 1) in uvec3 color;

vec2[4] vertices = {{-1.0, -1.0}, {1.0, -1.0}, {-1.0, 1.0}, {1.0, 1.0}};
vec2[4] coords = {{ 0.0, 0.0 }, { 1.0, 0.0 }, { 0.0, 1.0 }, { 1.0, 1.0 }};

layout(set = 0, binding = 0) uniform UniformGlobalObject {
  float window_ratio;
  float font_scale;
  float font_ratio;
  float font_width;
  float font_height;
  float glyph_width;
  float glyph_height;
  float cols_per_row;
  float atlas_cols;
  float padding;
} ugo;

void main() {
  float y = int(int(gl_InstanceIndex) / int(ugo.cols_per_row));
  float x = gl_InstanceIndex - int(y * ugo.cols_per_row);

  vec2 p = vertices[gl_VertexIndex] + vec2(x, y) * 2 + vec2(1.0, 1.0);
  vec2 vertex_position = ugo.font_scale * vec2(p.x * ugo.window_ratio * ugo.font_ratio, p.y) + vec2(-1.0, -1.0);

  gl_Position = vec4(vertex_position, 0.0, 1.0);

  float line = int(index / ugo.atlas_cols);
  float col = index - int(line * ugo.atlas_cols);

  frag_color = vec3(color) / 255.0;
  frag_texture_coords = vec2(ugo.glyph_width / ugo.font_width, ugo.glyph_height / ugo.font_height) * coords[gl_VertexIndex] + 
                        vec2(
                            col * (ugo.glyph_width + ugo.padding) / ugo.font_width,
                            line * (ugo.glyph_height + ugo.padding) / ugo.font_height
                        );
}
