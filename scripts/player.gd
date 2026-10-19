extends CharacterBody3D
# Third-person player with Free Fire style touch controls.

signal died
signal stats_changed(health: float, ammo: int, reserve: int, kills: int, weapon_name: String)

const WALK_SPEED := 4.4
const SPRINT_MULT := 1.6
const CROUCH_MULT := 0.5
const JUMP_SPEED := 5.4
const GRAVITY := 14.0
const PUNCH_DAMAGE := 20.0
const PUNCH_RANGE := 2.4
const PUNCH_CD := 0.55

var health := 100.0
var armor := 0.0
var kills := 0
var alive := true

var weapon := {}
var ammo := 0
var reserve := 0
var reloading := false
var fire_cd := 0.0
var punch_cd := 0.0
var crouching := false
var sprinting := false

var model: Node3D
var anim: AnimationPlayer
var hand: BoneAttachment3D
var gun_instance: Node3D
var cam: Camera3D
var cam_arm: SpringArm3D
var cap: CapsuleShape3D
var cap_shape: CollisionShape3D
var yaw := 0.0
var pitch := -0.18
var _cur_anim := ""

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	cap = CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	cap_shape = CollisionShape3D.new()
	cap_shape.shape = cap
	cap_shape.position = Vector3(0, 0.85, 0)
	add_child(cap_shape)

	model = _instantiate("res://models/soldier.glb")
	if model != null:
		add_child(model)
		anim = _find_anim_player(model)
		_setup_hand()

	cam_arm = SpringArm3D.new()
	cam_arm.spring_length = 4.2
	cam_arm.position = Vector3(0, 1.7, 0)
	cam_arm.collision_mask = 1
	add_child(cam_arm)
	cam_arm.add_excluded_object(get_rid())
	cam = Camera3D.new()
	cam.fov = 65.0
	cam.current = true
	cam_arm.add_child(cam)
	stats_changed.emit(health, ammo, reserve, kills, _weapon_name())

func _instantiate(path: String) -> Node3D:
	var scene: PackedScene = load(path)
	if scene == null:
		return null
	return scene.instantiate()

func _find_anim_player(root: Node) -> AnimationPlayer:
	var found := root.find_children("*", "AnimationPlayer", true, false)
	return found[0] if found.size() > 0 else null

func _setup_hand() -> void:
	var skels := model.find_children("*", "Skeleton3D", true, false)
	if skels.is_empty():
		return
	var skel: Skeleton3D = skels[0]
	var bone := -1
	for i in skel.get_bone_count():
		var n := String(skel.get_bone_name(i)).to_lower()
		if n.contains("hand") and not n.contains("left") and not n.contains("l_hand") and not n.contains("lhand"):
			bone = i
			break
	if bone == -1:
		for i in skel.get_bone_count():
			if String(skel.get_bone_name(i)).to_lower().contains("hand"):
				bone = i
				break
	if bone == -1:
		return
	hand = BoneAttachment3D.new()
	hand.bone_name = skel.get_bone_name(bone)
	skel.add_child(hand)

func _weapon_name() -> String:
	return String(weapon.get("name", ""))

func _physics_process(dt: float) -> void:
	if not alive:
		return
	fire_cd = maxf(0.0, fire_cd - dt)
	punch_cd = maxf(0.0, punch_cd - dt)

	var look := Controls.take_look()
	yaw -= look.x * 0.0035
	pitch = clampf(pitch - look.y * 0.0035, -1.25, 0.9)
	rotation.y = yaw
	cam_arm.rotation.x = pitch

	var want_crouch := Controls.action("crouch")
	if want_crouch != crouching:
		crouching = want_crouch
		cap.height = 1.2 if crouching else 1.7
		cap_shape.position.y = 0.6 if crouching else 0.85

	var mv := Controls.move_vec
	var dir := Vector3(mv.x, 0.0, mv.y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	dir = Basis(Vector3.UP, yaw) * dir
	sprinting = Controls.action("sprint") and dir.length() > 0.5 and not crouching
	var speed := WALK_SPEED
	if crouching:
		speed *= CROUCH_MULT
	elif sprinting:
		speed *= SPRINT_MULT
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= GRAVITY * dt
	elif Controls.just_pressed("jump") and not crouching:
		velocity.y = JUMP_SPEED
	move_and_slide()
	_update_anim(dir.length() * speed)

	if weapon.size() > 0:
		if Controls.just_pressed("reload"):
			_reload()
		elif Controls.action("fire") and fire_cd <= 0.0 and not reloading:
			if ammo <= 0:
				_reload()
			else:
				fire_cd = weapon.rate
				ammo -= 1
				_shoot()
				stats_changed.emit(health, ammo, reserve, kills, _weapon_name())

	var punch_now := Controls.action("punch") or (Controls.action("fire") and weapon.is_empty())
	if punch_now and punch_cd <= 0.0 and not reloading:
		punch_cd = PUNCH_CD
		_do_punch()

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
	if not is_on_floor():
		want = _pick_anim("jump")
	elif crouching:
		want = _pick_anim("crouch")
		if want == "":
			want = _pick_anim("sit")
	elif planar_speed > 6.0:
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

func _shoot() -> void:
	if cam == null:
		return
	var from := cam.global_position
	var dir := -cam.global_transform.basis.z
	var params := PhysicsRayQueryParameters3D.create(from, from + dir * float(weapon.range), 0xFFFFFFFF, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(params)
	if hit.has("collider"):
		var body: Object = hit.collider
		if body != null and body.has_method("take_damage"):
			body.take_damage(weapon.damage, self)

func pickup_weapon(kind: String) -> void:
	weapon = Weapons.by_kind(kind)
	ammo = int(weapon.ammo)
	reserve = int(weapon.reserve)
	reloading = false
	_attach_gun(kind)
	stats_changed.emit(health, ammo, reserve, kills, _weapon_name())

func _attach_gun(kind: String) -> void:
	if gun_instance != null:
		gun_instance.queue_free()
		gun_instance = null
	var scene: PackedScene = load(Weapons.by_kind(kind).model)
	if scene == null:
		return
	gun_instance = scene.instantiate()
	gun_instance.rotation_degrees = Vector3(0, -90, 0)
	gun_instance.position = Vector3(0.05, 0.05, 0.2)
	if hand != null:
		hand.add_child(gun_instance)
	elif model != null:
		gun_instance.position = Vector3(0.3, 1.2, 0.35)
		model.add_child(gun_instance)

func _reload() -> void:
	if reloading or weapon.is_empty() or ammo >= int(weapon.ammo):
		return
	reloading = true
	var need: int = int(weapon.ammo) - ammo
	var take: int = mini(need, reserve)
	await get_tree().create_timer(float(weapon.reload)).timeout
	reloading = false
	if not alive:
		return
	ammo += take
	reserve -= take
	stats_changed.emit(health, ammo, reserve, kills, _weapon_name())

func _do_punch() -> void:
	var punch_anim := _pick_anim("punch")
	if punch_anim != "" and anim.has_animation(punch_anim):
		anim.play(punch_anim, 0.1)
		_cur_anim = punch_anim
	var facing := Vector3(-sin(yaw), 0.0, -cos(yaw))
	for e in get_tree().get_nodes_in_group("enemies"):
		var node := e as Node3D
		if node == null or not node.visible:
			continue
		var to := node.global_position - global_position
		if to.length() <= PUNCH_RANGE and facing.dot(to.normalized()) > 0.25:
			if node.has_method("take_damage"):
				node.take_damage(PUNCH_DAMAGE, self)

func take_damage(dmg: float, _source: Node = null) -> void:
	if not alive:
		return
	var absorbed := minf(armor, dmg * 0.5)
	armor -= absorbed
	health -= (dmg - absorbed)
	stats_changed.emit(health, ammo, reserve, kills, _weapon_name())
	if health <= 0.0:
		health = 0.0
		alive = false
		velocity = Vector3.ZERO
		visible = false
		set_collision_layer_value(1, false)
		died.emit()

func add_kill() -> void:
	kills += 1
	stats_changed.emit(health, ammo, reserve, kills, _weapon_name())
