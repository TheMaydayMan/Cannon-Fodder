shader_type canvas_item;

uniform float scale = 100.0;
uniform vec2 offset = vec2(0, 0);
varying vec4 modulate;
void vertex() {
  modulate = COLOR;
}
void fragment() {
	COLOR = texture(TEXTURE, (FRAGCOORD.xy + offset) / scale) * modulate;
}
