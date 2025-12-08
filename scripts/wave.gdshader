shader_type canvas_item;

void fragment(){
	COLOR.rgb = texture(TEXTURE, UV).rgb * (1.0) + vec3(1,1,1);
}
