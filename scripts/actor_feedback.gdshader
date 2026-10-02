shader_type canvas_item;
#include "res://scripts/actor_feedback_common.gdshaderinc"

void fragment() {
	COLOR = rw_actor_color(COLOR);
}
