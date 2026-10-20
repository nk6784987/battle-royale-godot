extends Control
# Virtual joystick: touch in this area and drag to move.

var _idx := -1
var _center := Vector2.ZERO

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed and _idx == -1:
			_idx = ev.index
			_center = ev.position
			queue_redraw()
		elif not ev.pressed and ev.index == _idx:
			_idx = -1
			Controls.move_vec = Vector2.ZERO
			queue_redraw()
	elif ev is InputEventScreenDrag and ev.index == _idx:
		var v: Vector2 = (ev.position - _center) / 110.0
		if v.length() > 1.0:
			v = v.normalized()
		Controls.move_vec = Vector2(v.x, -v.y)
		queue_redraw()

func _draw() -> void:
	if _idx == -1:
		return
	draw_circle(_center, 78.0, Color(1, 1, 1, 0.14))
	draw_arc(_center, 78.0, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 2.0, true)
	draw_circle(_center + Vector2(Controls.move_vec.x, -Controls.move_vec.y) * 70.0, 30.0, Color(1, 1, 1, 0.35))
