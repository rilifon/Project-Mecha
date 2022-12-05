extends Node

const DATA_PATH = "res://database/parts/"

enum SIDE {LEFT, RIGHT, SINGLE}

onready var ARM_WEAPONS = {}
onready var SHOULDER_WEAPONS = {}
onready var SHOULDERS = {}
onready var CORES = {}
onready var HEADS = {}
onready var CHASSIS = {}
onready var CHASSIS_LEFT = {}
onready var CHASSIS_RIGHT = {}
onready var CHASSIS_SINGLE = {}
onready var GENERATORS = {}
onready var CHIPSETS = {}
onready var THRUSTERS = {}
onready var PROJECTILES = {}


func _ready():
	setup_parts()


func setup_parts():
	load_parts("arm_weapons", ARM_WEAPONS)
	load_parts("shoulder_weapons", SHOULDER_WEAPONS)
	load_parts("shoulders", SHOULDERS)
	load_parts("cores", CORES)
	load_parts("heads", HEADS)
	load_parts("chassis", CHASSIS)
	load_parts("generators", GENERATORS)
	load_parts("chipsets", CHIPSETS)
	load_parts("thrusters", THRUSTERS)
	load_parts("projectiles", PROJECTILES)
	
	setup_chassis_sides()


func setup_chassis_sides():
	for key in CHASSIS.keys():
		var chassis = CHASSIS[key]
		if chassis.side == SIDE.LEFT:
			CHASSIS_LEFT[key] = chassis
		elif chassis.side == SIDE.RIGHT:
			CHASSIS_RIGHT[key] = chassis
		elif chassis.side == SIDE.SINGLE:
			CHASSIS_SINGLE[key] = chassis
		else:
			push_error("Not a valid chassis side type: " + str(chassis.side))


func load_parts(name, dict):
	var dir = Directory.new()
	var path = DATA_PATH + name + "/"
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name != "." and file_name != "..":
				var key = file_name.replace(".tres", "").replace(".tscn", "")
				dict[key] = load(path + file_name)
				if dict[key] is PackedScene:
					dict[key] = dict[key].instance()
			file_name = dir.get_next()
	else:
		push_error("An error occurred when trying to access part path.")
		assert(false)


func get_parts(type):
	match type:
		"arm_weapon":
			return ARM_WEAPONS
		"shoulder_weapon":
			return SHOULDER_WEAPONS
		"shoulders":
			return SHOULDERS
		"core":
			return CORES
		"head":
			return HEADS
		"chassis":
			return CHASSIS
		"chassis_left":
			return CHASSIS_LEFT
		"chassis_right":
			return CHASSIS_RIGHT
		"chassis_single":
			return CHASSIS_SINGLE
		"generator":
			return GENERATORS
		"chipset":
			return CHIPSETS
		"thruster":
			return THRUSTERS
		"projectile":
			return PROJECTILES
		_:
			push_error("Not a valid type of part: " + str(type))
			return false


func get_part(type, name):
	var table = get_parts(type)
	assert(table.has(name), "Not a existent part: " + str(name))
	return table[name]


func get_random_part_name(type):
	var table = get_parts(type)
	return table.keys()[randi()%table.keys().size()]

func get_max_stat_value(stat_name):
	var max_value = 0.0
	var categories = [ARM_WEAPONS, SHOULDER_WEAPONS, SHOULDERS, CORES, HEADS, CHASSIS, GENERATORS, CHIPSETS, THRUSTERS]
	for parts in categories:
		var current_max = 0
		for part in parts.values():
			if part.get(stat_name) and part.get(stat_name) > current_max:
				current_max = part.get(stat_name)
		max_value += current_max
	return float(max_value)
