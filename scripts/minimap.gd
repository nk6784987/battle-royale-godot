extends Control
# Small radar: player in green, bots in red, safe zone circle in blue.

const RANGE := 200.0

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	var c := size / 2.0
	var half := size.x / 2.0
	draw_circle(c, half, Color(0, 0, 0, 0.55))
	draw_arc(c, half, 0.0, TAU, 48, Color(1, 1, 1, 0.6), 2.0, true)
	var main := get_tree().current_scene
	if main != null and "zone_radius" in main:
		var zr: float = main.zone_radius / RANGE * half
		draw_arc(c, zr, 0.0, TAU, 64, Color(0.3, 0.6, 1.0), 2.0, true)
	for n in get_tree().get_nodes_in_group("enemies"):
		var b := n as Node3D
		if b != null and b.visible:
			draw_circle(c + _rel(b.global_position) * half, 4.0, Color(1.0, 0.25, 0.2))
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as Node3D
		if p != null and p.visible:
			draw_circle(c + _rel(p.global_position) * half, 5.0, Color(0.2, 1.0, 0.4))

func _rel(pos: Vector3) -> Vector2:
	return Vector2(pos.x / RANGE, pos.z / RANGE)
