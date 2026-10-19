extends Area3D
# A weapon lying on the ground. Spins and bobs so it is easy to spot.

var kind := "ak"
var _t := 0.0

func _ready() -> void:
	add_to_group("loot")
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 1.4, 1.8)
	shape.shape = box
	add_child(shape)
	var scene: PackedScene = load(Weapons.by_kind(kind).model)
	if scene != null:
		var m := scene.instantiate()
		m.scale = Vector3.ONE * 1.2
		m.position = Vector3(0, 0.3, 0)
		add_child(m)
	body_entered.connect(_on_body)

func _process(dt: float) -> void:
	_t += dt
	rotate_y(dt * 1.6)
	position.y = 0.5 + sin(_t * 2.2) * 0.08

func _on_body(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("pickup_weapon"):
		body.pickup_weapon(kind)
		queue_free()
