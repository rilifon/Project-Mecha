extends Mecha

const LOGIC = preload("res://game/mecha/enemy_logic/EnemyLogic.gd")


var arena
var health = 100
var speed = 100
var mov_vec = Vector2()
var going_to_position = false
var REACH_RANGE = 1
var logic
var all_mechas
var valid_target = false
var engage_distance = 2000
var shooting_distance = 3500
var random_pos_targeting_distance = 700
var current_state
var move_d_rand = 50
var pos_for_blocked
var old_region


func _ready():
	logic = LOGIC.new()
	logic.setup("default")


func _process(delta):
	if paused or is_stunned():
		return

	logic.update(self)
	logic.run(self, delta)
	
	if Debug.get_setting("enemy_state"):
		$Debug/StateLabel.text = logic.get_current_state()
	else:
		$Debug/StateLabel.text = ""


func setup(arena_ref, is_tutorial):
	arena = arena_ref
	mecha_name = "Mecha " + str(randi()%2000)
	if is_tutorial:
		set_generator("type_2")
		set_core(PartManager.get_random_part_name("core"))
		set_head(PartManager.get_random_part_name("head"))
		set_leg(PartManager.get_random_part_name("leg_single"), SIDE.SINGLE)
		set_arm_weapon(false, SIDE.RIGHT)
		set_arm_weapon(false, SIDE.LEFT)
		set_shoulder_weapon(false, SIDE.RIGHT)
		set_shoulder_weapon(false, SIDE.LEFT)
		set_shoulder(PartManager.get_random_part_name("shoulder_left"), SIDE.LEFT)
		set_shoulder(PartManager.get_random_part_name("shoulder_right"), SIDE.RIGHT)
		scale = Vector2(0.5, 0.5)
	else:
		set_generator("type_1")
		set_core(PartManager.get_random_part_name("core"))
		set_head(PartManager.get_random_part_name("head"))
		set_leg(PartManager.get_random_part_name("leg_left"), SIDE.LEFT)
		set_leg(PartManager.get_random_part_name("leg_right"), SIDE.RIGHT)
		set_arm_weapon(PartManager.get_random_part_name("arm_weapon"), SIDE.RIGHT)
		set_arm_weapon(PartManager.get_random_part_name("arm_weapon") if randf() > .5 else false, SIDE.LEFT)
		set_shoulder_weapon(PartManager.get_random_part_name("shoulder_weapon") if randf() > .8 else false, SIDE.RIGHT)
		set_shoulder_weapon(PartManager.get_random_part_name("shoulder_weapon") if randf() > .9 else false, SIDE.LEFT)
		set_shoulder(PartManager.get_random_part_name("shoulder_left"), SIDE.LEFT)
		set_shoulder(PartManager.get_random_part_name("shoulder_right"), SIDE.RIGHT)
	
	#For the moment hard set enemies' movement type to free
	movement_type = "free"

#Auxiliary functions

func check_for_targets():
	#Check if current target is still in distance
	if valid_target and is_instance_valid(valid_target):
		if position.distance_to(valid_target.position) > shooting_distance:
			valid_target = false
	else:
		valid_target = false
	
	#Find new target
	if not valid_target:
		var min_distance = 99999999
		for target in arena.get_mechas():
			var distance = position.distance_to(target.position)
			if target != self and distance <= engage_distance and distance < min_distance:
				valid_target = target
				min_distance = distance


func shoot_weapons():
	try_to_shoot("arm_weapon_left")
	try_to_shoot("arm_weapon_right")
	try_to_shoot("shoulder_weapon_left")
	try_to_shoot("shoulder_weapon_right")


func try_to_shoot(name):
	var node = get_weapon_part(name)
	if node:
		if node.can_reload() == "yes" and node.is_clip_empty() and not node.is_reloading():
			node.reload()
		elif node.can_shoot():
			shoot(name)

# Navigation

func random_targeting_pos():
	var rand_pos = Vector2()
	var angle = rand_range(0, 2.0*PI)
	var direction = Vector2(cos(angle), sin(angle)).normalized()
	var rand_radius = rand_range(400, 800)
	rand_pos = valid_target.position + direction * rand_radius
	
	return rand_pos


func get_navigation_path():
	return NavAgent.get_nav_path()


func navigate_to_target(dt):
	if going_to_position:
		var target = NavAgent.get_next_location()
		var pos = get_global_transform().origin
		var dir = (target - pos).normalized()
		apply_rotation_by_point(dt, target, false)
		apply_movement(dt, dir)


func get_target_navigation_pos():
	if going_to_position:
		return NavAgent.get_final_location()
	return false


func _on_NavigationAgent2D_navigation_finished():
	going_to_position = false


func _on_NavigationAgent2D_velocity_computed(safe_velocity):
	velocity = move_and_slide(safe_velocity)


func _on_NavigationAgent2D_target_reached():
	going_to_position = false
