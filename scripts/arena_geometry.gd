extends RefCounted
## Shared world bounds. Spawn and cleanup must not depend on window size.
const SIZE := Vector2(1920, 1080)
const RECT := Rect2(Vector2.ZERO, SIZE)

static func visual_bounds(actor: Node2D) -> Rect2:
	var bounds := Rect2(actor.global_position, Vector2.ZERO)
	var found := false
	var pending: Array[Node] = [actor]
	while not pending.is_empty():
		var node = pending.pop_back()
		pending.append_array(node.get_children())
		if not node is Node2D or not node.is_visible_in_tree():
			continue
		var rect := Rect2()
		if node is Sprite2D and node.texture != null:
			rect = node.get_rect()
		elif node is AnimatedSprite2D and node.sprite_frames != null:
			var texture: Texture2D = node.sprite_frames.get_frame_texture(node.animation, node.frame)
			if texture == null:
				continue
			rect = Rect2(node.offset, texture.get_size())
			if node.centered:
				rect.position -= rect.size * 0.5
		else:
			continue
		var world: Rect2 = node.global_transform * rect
		bounds = bounds.merge(world) if found else world
		found = true
	return bounds.grow(16.0)
