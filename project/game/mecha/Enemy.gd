extends Mecha

const LOGIC = preload("res://game/mecha/enemy_logic/EnemyLogic.gd")

var health = 100
var speed = 100
var mov_vec = Vector2()
var moving = false
var final_pos = false
var REACH_RANGE = 1
var logic
var all_mechas
var valid_target = false
var engage_distance = 800
var shooting_distance = 200
var current_state
var move_d_rand = 50
var navigation_node
var path : Array = []
var pos_for_blocked
var regions = [1, 2, 3, 4]
var old_region
var arena_size = Vector2(1500, 1000)


func _ready():
	logic = LOGIC.new()
	logic.setup()


func _process(delta):
	var state = logic.get_current_state()
	check_for_targets()
	print(state)
	if has_method("do_"+state):
		call("do_"+state, delta)
		
	logic.updateFiniteLogic(self)
	
	$Label.text = logic.get_current_state()


func setup(_all_mechas, _path_stuff):
	all_mechas = _all_mechas
	navigation_node = _path_stuff
	set_max_life(100)
	set_core("core_test")
	set_head("head_test")
	set_legs(false)
	set_arm_weapon("test_weapon1", SIDE.RIGHT)
	set_arm_weapon("test_weapon1", SIDE.LEFT)
	set_shoulder_weapon("test_weapon1", SIDE.RIGHT)
	set_shoulder_weapon("test_weapon1", SIDE.LEFT)
	set_shoulder("shoulder_test_left", SIDE.LEFT)
	set_shoulder("shoulder_test_right", SIDE.RIGHT)


func shoot_weapons():
	if arm_weapon_left:
		shoot("left_arm_weapon")
	if arm_weapon_right:
		shoot("right_arm_weapon")
	if shoulder_weapon_left:
		shoot("left_shoulder_weapon")
	if shoulder_weapon_right:
		shoot("right_shoulder_weapon")


func random_pos():
	var screen_x = arena_size.x
	var screen_y = arena_size.y
	var new_region
	randomize()
	regions.shuffle()
	new_region = regions[0]
		
	if new_region != old_region:
		old_region = new_region
		if new_region == 1:
			return Vector2(rand_range(move_d_rand, screen_x/2),\
					  	   rand_range(move_d_rand, screen_y/2))
		elif new_region == 2:
			return Vector2(rand_range(screen_x/2, screen_x),\
					  	   rand_range(move_d_rand, screen_y/2))
		elif new_region == 3:
			return Vector2(rand_range(move_d_rand, screen_x/2),\
					  	   rand_range(screen_y/2, screen_y))
		else:
			return Vector2(rand_range(screen_x/2, screen_x),\
					  	   rand_range(screen_y/2, screen_y))
	else:
		old_region = regions[1]
		if new_region == 1:
			return Vector2(rand_range(move_d_rand, screen_x/2),\
					  	   rand_range(move_d_rand, screen_y/2))
		elif new_region == 2:
			return Vector2(rand_range(screen_x/2, screen_x),\
					  	   rand_range(move_d_rand, screen_y/2))
		elif new_region == 3:
			return Vector2(rand_range(move_d_rand, screen_x/2),\
					  	   rand_range(screen_y/2, screen_y))
		else:
			return Vector2(rand_range(screen_x/2, screen_x),\
					  	   rand_range(screen_y/2, screen_y))
		
		

func random_pos_targeting():
	randomize()
	var v_closeness = Vector2()
	var rand_pos = Vector2()
	
	## ifs to check where the enemy is and add the proper distance between them
	if position.x - valid_target.position.x < 0:
		v_closeness.x = -500
	else:
		v_closeness.x = 500
	
	if position.x - valid_target.position.y < 0:
		v_closeness.y = -500
	else:
		v_closeness.y = 500
	
	rand_pos = Vector2(rand_range(max(move_d_rand, valid_target.position.x-move_d_rand+v_closeness.x),\
				   (move_d_rand)),\
				   rand_range(max(move_d_rand, valid_target.position.y-move_d_rand+v_closeness.y),\
				   (move_d_rand)))
	
	return navigation_node.get_closest_point(rand_pos)


func do_roaming(delta):
	if not final_pos:
		final_pos = random_pos()
	
	if not path:
		path = navigation_node.get_simple_path(self.global_position, final_pos)
	
	
	if path.size() > 0:
		
		apply_rotation(delta, Vector2(path[0].x-position.x,\
				   			  path[0].y-position.y), false)
								
		apply_movement(delta, Vector2(path[0].x-position.x,\
				   			  path[0].y-position.y))
		
		if global_position.distance_to(path[0]) <= 1:
			path.pop_front()
			if path.size() == 0:
				final_pos = random_pos()
				path = navigation_node.get_simple_path(self.global_position, final_pos)
	
		
	if not valid_target:
		check_for_targets()

	
	
func do_targeting(delta):
	if not valid_target:
		return
	
	var enemy_area_point
	
	if not final_pos or position.distance_to(final_pos) < 10:
		enemy_area_point = random_pos_targeting()
	
	if not path:
		path = navigation_node.get_simple_path(self.position, enemy_area_point)
	
	if path.size() > 0:		
		for place in path:
			apply_rotation(delta, valid_target.position, false)
			apply_movement(delta,  Vector2(path[0].x-position.x,\
				   			  	   path[0].y-position.y))

	shoot_weapons()


func do_idle(_delta):
	pass


func check_for_targets():
	var target_to_return
	
	for target in all_mechas:
		if target != self and position.distance_to(target.position) < engage_distance:
			target_to_return = target
		
	for target in all_mechas:
		if target_to_return:
			if position.distance_to(target_to_return.position) > position.distance_to(target.position):
				target_to_return = target				
		
	if target_to_return:
		valid_target = target_to_return
	else:
		valid_target = false

 
