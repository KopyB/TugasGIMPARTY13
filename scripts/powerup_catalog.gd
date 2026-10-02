extends RefCounted
## One source of copy for pickup cards and the pause guide.

const ENTRIES := {
	"Shield": ["powerup icon/2shield icon (1).png", "Blocks one hit", "Absorbs one hit, then breaks. Lasts until it is used."],
	"Second Wind": ["Icon.png", "Revives you once", "Revives your ship after a fatal hit and clears enemies with a shockwave."],
	"Kraken Slayer": ["KrakenSlayerIcon.png", "Fires a giant beam", "Charges a powerful forward beam that damages enemies in its path."],
	"Artillery": ["powerup icon/ArtilleryBurstIcon.png", "Fires faster", "Temporarily increases your firing rate. Combines with Multishot."],
	"Multishot": ["powerup icon/MultishotIcon.png", "Fires three shots", "Fires a forward shot and two angled shots. Combines with Artillery."],
	"SPEED IS KEY": ["powerup icon/Untitled1071_20251123144740.png", "Move and turn faster", "Temporarily increases movement and turning speed for quick dodges."],
	"Admiral's Will": ["powerup icon/AdmiralWillIcon.png", "Stuns enemies", "Releases a shockwave and lightning strikes, temporarily paralyzing enemies."],
	"Dizziness": ["powerup icon/Debuff icon.png", "Controls reversed", "A siren scream reverses movement controls. The HUD shows the remaining time. Another scream refreshes the effect."]
}

static func make_card(title: String, details: bool = false) -> PanelContainer:
	var entry: Array = ENTRIES.get(title, ["Icon.png", "Power collected", "Power collected."])
	var panel := PanelContainer.new()
	panel.theme = preload("res://themes/nautical.tres")
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.18, 0.25, 0.96)
	style.border_color = Color(0.48, 0.79, 0.8, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/art/" + str(entry[0])) as Texture2D
	icon.custom_minimum_size = Vector2(52, 52)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 24)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(heading)
	var description := Label.new()
	description.text = str(entry[2] if details else entry[1])
	description.add_theme_font_size_override("font_size", 20)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(description)
	return panel
