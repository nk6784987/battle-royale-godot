class_name Weapons

const AK := {
	"name": "AK47",
	"model": "res://models/ak47.glb",
	"damage": 24.0,
	"rate": 0.12,
	"ammo": 30,
	"reserve": 120,
	"reload": 2.2,
	"range": 220.0,
}
const SNIPER := {
	"name": "Sniper",
	"model": "res://models/sniper.glb",
	"damage": 90.0,
	"rate": 1.4,
	"ammo": 5,
	"reserve": 20,
	"reload": 3.0,
	"range": 420.0,
}

static func by_kind(kind: String) -> Dictionary:
	if kind == "sniper":
		return SNIPER
	return AK
