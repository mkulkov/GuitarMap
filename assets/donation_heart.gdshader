shader_type canvas_item;
render_mode unshaded;


void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float alpha = smoothstep(0.035, 0.18, source.r);
	COLOR = vec4(source.rgb, alpha);
}
