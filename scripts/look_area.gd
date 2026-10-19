extends Control
# Full-screen touch area: drag anywhere not covered by UI to turn the camera.

var _idx := -1
var _last := Vector2.ZERO

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed and _idx == -1:
			_idx = ev.index
			_last = ev.position
		elif not ev.pressed and ev.index == _idx:
			_idx = -1
	elif ev is InputEventScreenDrag and ev.index == _idx:
		Controls.look_delta += ev.position - _last
		_last = ev.position
