extends Node3D
# Battle royale match: world, bots, loot, shrinking zone, win/lose.

const BOT_COUNT := 9
const LOOT_COUNT := 14
const MAP_HALF := 190.0
const ZONE_START := 170.0
const ZONE_MIN := 20.0
const ZONE_TIME := 300.0
const ZONE_DPS := 3.0

var player: CharacterBody3D
var bots: Array = []
var zone_radius := ZONE_START
var zone_left := ZONE_TIME
var hud: CanvasLayer
var match_running := false
var zone_ring: MeshInstance3D

func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_props()
	hud = preload("res://scripts/hud.gd").new()
	add_child(hud)
	hud.start_requested.connect(_start_match)
	hud.set_zone(zone_radius, zone_left)

func _start_match() -> void:
	if match_running:
		return
	match_running = true
	player = preload("res://scripts/player.gd").new()
	add_child(player)
	player.global_position = Vector3(0, 1.0, 0)
	player.died.connect(_on_player_died)
	player.stats_changed.connect(hud.update_stats)
	for i in BOT_COUNT:
		var bot := preload("res://scripts/bot.gd").new()
		bot.kind = "ak" if randf() < 0.8 else "sniper"
		bot.tint = Color.from_hsv(randf(), 0.55, 0.85)
		add_child(bot)
		bot.global_position = Vector3(randf_range(-MAP_HALF, MAP_HALF), 1.0, randf_range(-MAP_HALF, MAP_HALF))
		bot.bot_died.connect(_on_bot_died)
		bots.append(bot)
	hud.set_alive(bots.size() + 1)
	for i in LOOT_COUNT:
		var kind := "sniper" if randf() < 0.3 else "ak"
		spawn_loot(Vector3(randf_range(-MAP_HALF, MAP_HALF), 0.5, randf_range(-MAP_HALF, MAP_HALF)), kind)

func spawn_loot(pos: Vector3, kind: String) -> void:
	var loot := preload("res://scripts/loot.gd").new()
	loot.kind = kind
	add_child(loot)
	loot.global_position = pos

func _on_bot_died(bot: Node3D) -> void:
	if player != null and player.get("alive") and player.has_method("add_kill"):
		player.add_kill()
	spawn_loot(bot.global_position, "ak")
	bots.erase(bot)
	hud.set_alive(bots.size() + 1)
	if bots.is_empty():
		_end_match(true)

func _on_player_died() -> void:
	_end_match(false)

func _end_match(won: bool) -> void:
	if not match_running:
		return
	match_running = false
	hud.show_end(won)

func _physics_process(dt: float) -> void:
	if not match_running:
		return
	zone_left = maxf(0.0, zone_left - dt)
	var t := 1.0 - zone_left / ZONE_TIME
	zone_radius = maxf(ZONE_MIN, lerpf(ZONE_START, ZONE_MIN, t))
	if zone_ring != null:
		zone_ring.scale = Vector3(zone_radius, 1.0, zone_radius)
	for n in get_tree().get_nodes_in_group("enemies"):
		var b := n as Node3D
		if b != null and b.global_position.length() > zone_radius:
			if b.has_method("take_damage"):
				b.take_damage(ZONE_DPS * dt, self)
	if player != null and player.get("alive") and player.global_position.length() > zone_radius:
		player.take_damage(ZONE_DPS * dt, self)
	hud.set_zone(zone_radius, zone_left)

func _build_environment() -> void:
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = Color(0.25, 0.5, 0.85)
	mat.sky_horizon_color = Color(0.75, 0.8, 0.9)
	mat.ground_bottom_color = Color(0.2, 0.25, 0.2)
	mat.ground_horizon_color = Color(0.7, 0.75, 0.8)
	var sky := Sky.new()
	sky.sky_material = mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = false
	add_child(sun)

func _build_ground() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(500, 1, 500)
	shape.shape = box
	body.add_child(shape)
	shape.position = Vector3(0, -0.5, 0)
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(500, 500)
	mesh.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.35, 0.45, 0.25)
	gmat.roughness = 1.0
	mesh.material_override = gmat
	add_child(mesh)
	zone_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.97
	torus.outer_radius = 1.0
	zone_ring.mesh = torus
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.3, 0.6, 1.0, 0.55)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	zone_ring.material_override = rmat
	zone_ring.position = Vector3(0, 0.3, 0)
	zone_ring.scale = Vector3(zone_radius, 1.0, zone_radius)
	add_child(zone_ring)

func _build_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for i in 40:
		var h := rng.randf_range(3.0, 6.0)
		var trunk := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.25
		cyl.bottom_radius = 0.4
		cyl.height = h
		trunk.mesh = cyl
		var tm := StandardMaterial3D.new()
		tm.albedo_color = Color(0.35, 0.22, 0.12)
		trunk.material_override = tm
		var top := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = rng.randf_range(1.5, 2.6)
		sph.height = sph.radius * 2.0
		top.mesh = sph
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color(0.2, 0.5, 0.2)
		top.material_override = gm
		var tree := Node3D.new()
		var tp := Vector3(rng.randf_range(-MAP_HALF, MAP_HALF), 0, rng.randf_range(-MAP_HALF, MAP_HALF))
		add_child(tree)
		tree.global_position = tp
		trunk.position.y = h / 2.0
		tree.add_child(trunk)
		top.position.y = h + sph.radius * 0.7
		tree.add_child(top)
	for i in 25:
		var rock := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var s := rng.randf_range(0.8, 2.5)
		bm.size = Vector3(s, s * 0.8, s)
		rock.mesh = bm
		var rm := StandardMaterial3D.new()
		rm.albedo_color = Color(0.45, 0.45, 0.48)
		rock.material_override = rm
		rock.position = Vector3(rng.randf_range(-MAP_HALF, MAP_HALF), s * 0.4, rng.randf_range(-MAP_HALF, MAP_HALF))
		add_child(rock)
	for i in 8:
		var house := MeshInstance3D.new()
		var hm := BoxMesh.new()
		hm.size = Vector3(rng.randf_range(6.0, 10.0), 4.0, rng.randf_range(6.0, 10.0))
		house.mesh = hm
		var hmat := StandardMaterial3D.new()
		hmat.albedo_color = Color(0.75, 0.68, 0.55)
		house.material_override = hmat
		var hp := Vector3(rng.randf_range(-150, 150), 2.0, rng.randf_range(-150, 150))
		house.position = hp
		add_child(house)
		var hbody := StaticBody3D.new()
		add_child(hbody)
		var hsh := CollisionShape3D.new()
		var hbx := BoxShape3D.new()
		hbx.size = hm.size
		hsh.shape = hbx
		hbody.global_position = hp
		hbody.add_child(hsh)
