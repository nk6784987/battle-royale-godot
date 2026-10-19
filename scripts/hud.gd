extends CanvasLayer
# Mobile HUD: joystick, action buttons, stats, minimap, menus.

signal start_requested

var _health_bar: ProgressBar
var _ammo_label: Label
var _weapon_label: Label
var _kills_label: Label
var _alive_label: Label
var _zone_label: Label
var _menu: Control
var _end: Control
var _end_label: Label

func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var look := preload("res://scripts/look_area.gd").new()
	look.set_anchors_preset(Control.PRESET_FULL_RECT)
	look.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(look)

	var joy := preload("res://scripts/joystick.gd").new()
	joy.position = Vector2(0, 360)
	joy.size = Vector2(520, 360)
	root.add_child(joy)

	_add_button(root, "FIRE", Vector2(1090, 560), Vector2(130, 130), "fire")
	_add_button(root, "PUNCH", Vector2(1000, 445), Vector2(105, 105), "punch")
	_add_button(root, "JUMP", Vector2(995, 595), Vector2(85, 85), "jump")
	_add_button(root, "CROUCH", Vector2(890, 595), Vector2(95, 85), "crouch")
	_add_button(root, "SPRINT", Vector2(890, 470), Vector2(95, 60), "sprint")
	_add_button(root, "RELOAD", Vector2(1120, 60), Vector2(110, 55), "reload")

	var info := VBoxContainer.new()
	info.position = Vector2(16, 12)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_constant_override("separation", 4)
	root.add_child(info)
	_weapon_label = _label("Bare Hands")
	info.add_child(_weapon_label)
	_ammo_label = _label("Punch: 20 dmg")
	info.add_child(_ammo_label)
	_kills_label = _label("Kills: 0")
	info.add_child(_kills_label)
	_alive_label = _label("Alive: 10")
	info.add_child(_alive_label)
	_zone_label = _label("Zone: 5:00")
	info.add_child(_zone_label)
	_health_bar = ProgressBar.new()
	_health_bar.min_value = 0
	_health_bar.max_value = 100
	_health_bar.value = 100
	_health_bar.custom_minimum_size = Vector2(240, 22)
	_health_bar.show_percentage = false
	_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(_health_bar)

	var mini := preload("res://scripts/minimap.gd").new()
	mini.position = Vector2(1080, 150)
	mini.size = Vector2(180, 180)
	mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mini)

	_menu = _overlay(root)
	var cc: CenterContainer = _menu.get_child(0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	cc.add_child(vb)
	var title := _label("BATTLE ROYALE")
	title.add_theme_font_size_override("font_size", 46)
	vb.add_child(title)
	vb.add_child(_label("Free Fire style mobile battle - Godot 4"))
	var start := Button.new()
	start.text = "START MATCH"
	start.custom_minimum_size = Vector2(280, 64)
	start.add_theme_font_size_override("font_size", 24)
	start.pressed.connect(func() -> void:
		_menu.visible = false
		start_requested.emit())
	vb.add_child(start)

	_end = _overlay(root)
	_end.visible = false
	var cc2: CenterContainer = _end.get_child(0)
	var vb2 := VBoxContainer.new()
	vb2.add_theme_constant_override("separation", 16)
	cc2.add_child(vb2)
	_end_label = _label("BOOYAH!")
	_end_label.add_theme_font_size_override("font_size", 52)
	vb2.add_child(_end_label)
	var restart := Button.new()
	restart.text = "PLAY AGAIN"
	restart.custom_minimum_size = Vector2(260, 60)
	restart.add_theme_font_size_override("font_size", 22)
	restart.pressed.connect(func() -> void: get_tree().reload_current_scene())
	vb2.add_child(restart)

func _overlay(parent: Control) -> Control:
	var rect := ColorRect.new()
	rect.color = Color(0.02, 0.03, 0.05, 0.92)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(rect)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.add_child(cc)
	return rect

func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 5)
	return l

func _add_button(parent: Control, text: String, pos: Vector2, sz: Vector2, action: String) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	b.add_theme_font_size_override("font_size", 20)
	b.button_down.connect(func() -> void: Controls.set_action(action, true))
	b.button_up.connect(func() -> void: Controls.set_action(action, false))
	parent.add_child(b)

func update_stats(health: float, ammo: int, reserve: int, kills: int, weapon_name: String) -> void:
	_health_bar.value = health
	if weapon_name == "":
		_weapon_label.text = "Bare Hands"
		_ammo_label.text = "Punch: 20 dmg"
	else:
		_weapon_label.text = weapon_name
		_ammo_label.text = "Ammo: %d / %d" % [ammo, reserve]
	_kills_label.text = "Kills: %d" % kills

func set_alive(n: int) -> void:
	_alive_label.text = "Alive: %d" % n

func set_zone(radius: float, left: float) -> void:
	var mins := int(left) / 60
	var secs := int(left) % 60
	_zone_label.text = "Zone: %d:%02d (%dm)" % [mins, secs, int(radius)]

func show_end(won: bool) -> void:
	_end.visible = true
	_end_label.text = "BOOYAH!" if won else "ELIMINATED"
