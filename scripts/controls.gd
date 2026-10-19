extends Node
# Touch + keyboard input hub. HUD writes touch state here, gameplay reads it.

var move_vec := Vector2.ZERO
var look_delta := Vector2.ZERO
var _actions := {}
var _prev := {}

func _ready() -> void:
	for a in ["fire", "punch", "jump", "crouch", "sprint", "reload"]:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.2)
	_desktop_key("fire", KEY_F)
	_desktop_mouse("fire", MOUSE_BUTTON_LEFT)
	_desktop_key("punch", KEY_Q)
	_desktop_key("jump", KEY_SPACE)
	_desktop_key("crouch", KEY_C)
	_desktop_key("sprint", KEY_SHIFT)
	_desktop_key("reload", KEY_R)

func _desktop_key(action: String, key: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)

func _desktop_mouse(action: String, button: MouseButton) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)

func set_action(action: String, pressed: bool) -> void:
	_actions[action] = pressed

func action(action: String) -> bool:
	return _actions.get(action, false) or Input.is_action_pressed(action)

func just_pressed(action: String) -> bool:
	return _actions.get(action, false) and not _prev.get(action, false)

func take_look() -> Vector2:
	var d := look_delta
	look_delta = Vector2.ZERO
	return d

func _process(_dt: float) -> void:
	_prev = _actions.duplicate()
