extends Node2D

const PLAYER = preload("res://game/mecha/Player.tscn")
const ENEMY = preload("res://game/mecha/Enemy.tscn")


onready var NavInstance = $Navigation2D/NavigationPolygonInstance
onready var Mechas = $Mechas 
onready var Projectiles = $Projectiles
onready var PlayerHUD = $PlayerHUD
onready var ArenaCam = $ArenaCamera
onready var VCREffect = $ShaderEffects/VCREffect
onready var VCRTween = $ShaderEffects/Tween
onready var PauseMenu = $PauseMenu

var player
var current_cam
var all_mechas = []
var target_arena_zoom


func _ready():
	randomize()
	
	target_arena_zoom = ArenaCam.zoom
	
	update_navigation_polygon()
	
	add_player()
	for _i in range(10):
		add_enemy()


func _input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_B:
			$ShaderEffects/VCREffect.visible = !$ShaderEffects/VCREffect.visible
		if event.pressed and event.scancode == KEY_C:
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://game/arena/Arena.tscn")
		if event.pressed and event.scancode == KEY_ESCAPE:
			PauseMenu.toggle_pause()
	if ArenaCam.current:
		var amount = Vector2(.8, .8)
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_WHEEL_UP:
				target_arena_zoom -= amount
			elif event.button_index == BUTTON_WHEEL_DOWN:
				target_arena_zoom += amount


func _process(dt):
	update_shader_effect()
	update_arena_cam(dt)


func update_arena_cam(dt):
	if ArenaCam.current:
		var speed = 4600*(ArenaCam.zoom.x/10.0)
		var margin = 55
		var mpos = get_viewport().get_mouse_position()
		var move_vec = Vector2()
		if mpos.x <= margin:
			move_vec.x -= 1
		elif mpos.x >= get_viewport_rect().size.x - margin:
			move_vec.x += 1
		if mpos.y <= margin:
			move_vec.y -= 1
		elif mpos.y >= get_viewport_rect().size.y - margin:
			move_vec.y += 1
		
		ArenaCam.position += speed*dt*move_vec.normalized()
		
		ArenaCam.zoom = lerp(ArenaCam.zoom, target_arena_zoom, 10*dt)


func update_navigation_polygon():
	var arena_poly = NavInstance.navpoly
	
	#Add props collision to navigation
	var distance = 100
	var prop_polygons = []
	for i in range(0, $Props.get_child_count()):
		var prop = $Props.get_child(i)
		prop_polygons.append(prop.create_collision_polygon(distance))
		
	
	merge_polygons(prop_polygons)
	for polygon in prop_polygons:
		arena_poly.add_outline(polygon)
	arena_poly.make_polygons_from_outlines()
	
	NavInstance.set_navigation_polygon(arena_poly)
	NavInstance.enabled = false
	NavInstance.enabled = true


func merge_polygons(polygons):
	while(true):
		var merged_something = false
		for i in polygons.size():
			var polygon = polygons[i]
			for j in range(i + 1, polygons.size()):
				var other_polygon = polygons[j]
				var merged_polygon = Geometry.merge_polygons_2d(polygon, other_polygon)
				if merged_polygon.size() == 1 or Geometry.is_polygon_clockwise(merged_polygon[1]):
					polygons.append(merged_polygon[0])
					merged_something = [i, j]
					break
			if merged_something:
				break

		if not merged_something:
			break
		else:
			polygons.remove(merged_something[1])
			polygons.remove(merged_something[0])


func add_player():
	player = PLAYER.instance()
	Mechas.add_child(player)
	player.position = get_start_position(1)
	player.connect("create_projectile", self, "_on_mecha_create_projectile")
	player.connect("died", self, "_on_mecha_died")
	player.connect("lost_health", self, "_on_player_lost_health")
	all_mechas.push_back(player)
	PlayerHUD.setup(player, all_mechas)
	current_cam = player.get_cam()


func add_enemy():
	var enemy = ENEMY.instance()
	Mechas.add_child(enemy)
	enemy.position = get_random_start_position([1])
	enemy.connect("create_projectile", self, "_on_mecha_create_projectile")
	enemy.connect("died", self, "_on_mecha_died")
	all_mechas.push_back(enemy)
	enemy.setup(all_mechas, $Navigation2D)


func player_died():
	player = null
	ArenaCam.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	PlayerHUD.queue_free()
	current_cam = ArenaCam


func get_random_start_position(exclude_idx := []):
	var offset = 1000
	var rand_offset = Vector2(rand_range(-offset, offset), rand_range(-offset, offset))
	var n_pos = $StartPositions.get_child_count()
	var idx = randi()%n_pos + 1
	while exclude_idx.has(idx):
		idx = randi()%n_pos + 1
	return $StartPositions.get_node("Pos"+str(idx)).position + rand_offset


func get_start_position(idx):
	return $StartPositions.get_node("Pos"+str(idx)).position


func update_shader_effect():
	if player and not VCRTween.is_active():
		#Noise Intensity
		var target_noise = ((player.max_hp - player.hp)/float(player.max_hp)) * 0.0035
		var value = lerp(VCREffect.material.get_shader_param("noiseIntensity"), target_noise, .9)
		VCREffect.material.set_shader_param("noiseIntensity", value)
		#Color Offset Intensity
		value = lerp(VCREffect.material.get_shader_param("colorOffsetIntensity"), 0.175, .9)
		VCREffect.material.set_shader_param("colorOffsetIntensity", value)


func damage_burst_effect():
	if VCRTween.is_active():
		return
	VCRTween.interpolate_property(VCREffect.material, "shader_param/noiseIntensity", null, 0.02, .1)
	VCRTween.interpolate_property(VCREffect.material, "shader_param/colorOffsetIntensity", null, 1.2, .1)
	VCRTween.start()


func _on_player_lost_health():
	damage_burst_effect()


func _on_mecha_create_projectile(mecha, args):
	yield(get_tree().create_timer(args.delay), "timeout")
	var data = ProjectileManager.create(mecha, args)
	if data.create_node:
		Projectiles.add_child(data.node)


func _on_mecha_died(mecha):
	var idx = all_mechas.find(mecha)
	if idx != -1:
		all_mechas.remove(idx)
	if mecha == player:
		player_died()
