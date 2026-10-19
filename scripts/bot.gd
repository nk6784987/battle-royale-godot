extends CharacterBody3D
# AI bot: wanders, chases the player, shoots and punches up close.

signal bot_died(bot: Node3D)

const GRAVITY := 14.0
const WALK := 3.2
const RUN := 5.0
const SHOOT_RANGE := 45.0
const SHOOT_CD_MIN := 0.5
const SHOOT_CD_MAX := 1.4
const HIT_CHANCE := 0.38
const DAMAGE := 12.0
const PUNCH_RANGE := 2.2
const PUNCH_CD := 1.0
const PUNCH_DAMAGE := 10.0

var health := 100.0
var alive := true
var kind := "ak"
var tint := Color(0.85, 0.85, 0.85)
var _fire_cd := 1.0
var _punch_cd := 0.0
var _wander := Vector3.ZERO
var _wander_t := 0.0
var model: Node3D
var anim: AnimationPlayer
var _cur_anim := ""

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1
	collision_mask = 1
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	var shape := CollisionShape3D.new()
	shape.shape = cap
	shape.position = Vector3(0, 0.85, 0)
	add_child(shape)
	model = _instantiate("res://models/soldier.glb")
	if model != null:
		_tint(model)
		add_child(model)
		anim = _find_anim_player(model)
		_attach_gun()
	_fire_cd = randf_range(0.5, 1.5)

func _instantiate(path: String) -> Node3D:
	var scene: PackedScene = load(path)
	if scene == null:
		return null
	return scene.instantiate()

func _find_anim_player(root: Node) -> AnimationPlayer:
	var found := root.find_children("*", "AnimationPlayer", true, false)
	return found[0] if found.size() > 0 else null

func _tint(root: Node) -> void:
	for m in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := m as MeshInstance3D
		if mesh.mesh == null:
			continue
		var mat := mesh.mesh.surface_get_material(0)
		if mat is BaseMaterial3D:
			var dup: BaseMaterial3D = mat.duplicate()
			dup.albedo_color = tint
			mesh.set_surface_override_material(0, dup)

func _attach_gun() -> void:
	var skels := model.find_children("*", "Skeleton3D", true, false)
	if skels.is_empty():
		return
	var skel: Skeleton3D = skels[0]
	var bone := -1
	for i in skel.get_bone_count():
		if String(skel.get_bone_name(i)).to_lower().contains("hand"):
			bone = i
			break
	if bone == -1:
		return
	var att := BoneAttachment3D.new()
	att.bone_name = skel.get_bone_name(bone)
	skel.add_child(att)
	var scene: PackedScene = load(Weapons.by_kind(kind).model)
	if scene == null:
		return
	var g := scene.instantiate()
	g.rotation_degrees = Vector3(0, -90, 0)
	g.position = Vector3(0.05, 0.05, 0.2)
	att.add_child(g)

func _find_player() -> Node3D:
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as Node3D
		if p != null and p.visible and p.get("alive"):
			return p
	return null

func _physics_process(dt: float) -> void:
	if not alive:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * dt
	_fire_cd = maxf(0.0, _fire_cd - dt)
	_punch_cd = maxf(0.0, _punch_cd - dt)
	var player := _find_player()
	var moving := 0.0
	if player != null:
		var to := player.global_position - global_position
		var dist := to.length()
		if dist <= PUNCH_RANGE:
			velocity.x = 0.0
			velocity.z = 0.0
			if _punch_cd <= 0.0:
				_punch_cd = PUNCH_CD
				if player.has_method("take_damage"):
					player.take_damage(PUNCH_DAMAGE, self)
		elif dist < SHOOT_RANGE and _fire_cd <= 0.0:
			_fire_cd = randf_range(SHOOT_CD_MIN, SHOOT_CD_MAX)
			if randf() < HIT_CHANCE and player.has_method("take_damage"):
				player.take_damage(DAMAGE, self)
		elif dist < 60.0:
			var dir := Vector3(to.x, 0.0, to.z).normalized()
			velocity.x = dir.x * RUN
			velocity.z = dir.z * RUN
			moving = RUN
		else:
			moving = _wander_step(dt)
	else:
		moving = _wander_step(dt)
	var face_dir := Vector3(velocity.x, 0.0, velocity.z)
	if face_dir.length() > 0.3:
		rotation.y = atan2(-face_dir.x, -face_dir.z)
	move_and_slide()
	_update_anim(moving)

func _wander_step(dt: float) -> float:
	_wander_t -= dt
	if _wander_t <= 0.0:
		_wander_t = randf_range(2.0, 5.0)
		_wander = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
	velocity.x = _wander.x * WALK
	velocity.z = _wander.z * WALK
	return WALK

func _pick_anim(key: String) -> String:
	if anim == null:
		return ""
	for n in anim.get_animation_list():
		if String(n).to_lower().contains(key):
			return String(n)
	return ""

func _update_anim(planar_speed: float) -> void:
	if anim == null:
		return
	var want := ""
	if planar_speed > 4.0:
		want = _pick_anim("run")
	elif planar_speed > 0.3:
		want = _pick_anim("walk")
	if want == "":
		want = _pick_anim("idle")
	if want == "":
		return
	if want != _cur_anim and anim.has_animation(want):
		_cur_anim = want
		anim.play(_cur_anim, 0.25)

func take_damage(dmg: float, _source: Node = null) -> void:
	if not alive:
		return
	health -= dmg
	if health <= 0.0:
		alive = false
		visible = false
		set_collision_layer_value(1, false)
		bot_died.emit(self)
		queue_free()
