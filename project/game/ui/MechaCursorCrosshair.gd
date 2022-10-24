extends Control

signal enter_lock_mode
signal lock_area_entered
signal lock_area_exited

enum SIDE {LEFT, RIGHT}
enum MODES {NEUTRAL, RELOAD, ACTIVATING_LOCK, LOCK}

const ALPHA_SPEED = 8
const LOCKING_TIME_COOLDOWN = 1.0
const CROSSHAIRS = {
	"regular": preload("res://assets/images/ui/player_ui/cursor_crosshair.png"),
	"lock": preload("res://assets/images/ui/player_ui/lockon_crosshair.png"),
}

onready var LeftWeapon = $LeftWeapon
onready var LeftReload = $LeftReloadProgress
onready var RightWeapon = $RightWeapon
onready var RightReload = $RightReloadProgress
onready var Crosshair = $Crosshair
onready var ReloadLabel = $ReloadLabel
onready var ChangeModeProgress = $ChangeModeProgress
onready var CursorArea = $Crosshair/CursorArea

var cur_mode = MODES.NEUTRAL
var change_mode_timer := 0.0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	for node in [Crosshair, LeftWeapon, RightWeapon, LeftReload, RightReload]:
		set_alpha(node, 1.0)
	for node in [ReloadLabel, ChangeModeProgress]:
		set_alpha(node, 0.0)
	LeftReload.hide()
	RightReload.hide()

func _process(dt):
	rect_position = lerp(rect_position, get_global_mouse_position(), .80)
	
	match cur_mode:
		MODES.NEUTRAL:
			show_specific_nodes(dt, [Crosshair, LeftWeapon, RightWeapon, LeftReload, RightReload])
		MODES.RELOAD:
			show_specific_nodes(dt, [ReloadLabel, LeftWeapon, RightWeapon, LeftReload, RightReload])
		MODES.ACTIVATING_LOCK:
			show_specific_nodes(dt, [ChangeModeProgress])
		MODES.LOCK:
			show_specific_nodes(dt, [Crosshair])
	
	#Update changing-to-lock-mode progress
	if cur_mode == MODES.ACTIVATING_LOCK:
		change_mode_timer = min(change_mode_timer + dt, LOCKING_TIME_COOLDOWN)
		if change_mode_timer >= LOCKING_TIME_COOLDOWN:
			cur_mode = MODES.LOCK
			emit_signal("enter_lock_mode")
	else:
		change_mode_timer = max(change_mode_timer - 10*dt, 0.0)
	ChangeModeProgress.value = 100*change_mode_timer/float(LOCKING_TIME_COOLDOWN)
	
	if cur_mode == MODES.LOCK:
		Crosshair.texture = CROSSHAIRS.lock
	else:
		Crosshair.texture = CROSSHAIRS.regular


func set_cursor_collision_space(space):
	Physics2DServer.area_set_space(CursorArea.get_rid(), space)


func show_specific_nodes(dt, show_nodes):
	for node in [Crosshair, LeftWeapon, RightWeapon, LeftReload, RightReload,\
				 ReloadLabel, ChangeModeProgress]:
		if show_nodes.has(node):
			change_alpha(dt, node, 1.0)
		else:
			change_alpha(dt, node, 0.0)


func set_alpha(node, target_value):
	node.modulate.a = target_value


func change_alpha(dt, node, target_value):
	if node.modulate.a > target_value:
		node.modulate.a = max(node.modulate.a - dt*ALPHA_SPEED, target_value)
	else:
		node.modulate.a = min(node.modulate.a + dt*ALPHA_SPEED, target_value)


func get_side_node(side):
	if side == "left":
		return LeftWeapon
	elif side == "right":
		return RightWeapon
	else:
		push_error("Not a valid side: " + str(side))
		return null


func set_max_ammo(side, max_ammo):
	var node = get_side_node(side)
	if max_ammo is bool and not max_ammo:
		node.visible = false
	elif max_ammo is int:
		node.visible = true
		node.get_node("CurAmmo").text = "%02d" % max_ammo
		node.get_node("MaxAmmo").text = "%02d" % max_ammo
	else:
		push_error("Not a valid max_ammo value: " + str(max_ammo))


func set_ammo(side, ammo):
	var node = get_side_node(side)
	node.get_node("CurAmmo").text = "%02d" % ammo


func set_lock_mode(active):
	cur_mode = MODES.ACTIVATING_LOCK if active else MODES.NEUTRAL


func set_reload_mode(active):
	cur_mode = MODES.RELOAD if active else MODES.NEUTRAL


func reloading(reload_time, side):
	var weapon_node
	var reload_node
	if side == SIDE.LEFT:
		weapon_node = LeftWeapon
		reload_node = LeftReload
	elif side == SIDE.RIGHT:
		weapon_node = RightWeapon
		reload_node = RightReload
	else:
		push_error("Not a valid side: " + str(side))
	weapon_node.hide()
	reload_node.show()
	var tween = reload_node.get_node("Tween") as Tween
	tween.stop_all()
	tween.interpolate_property(reload_node, "value", 0, 100, reload_time, Tween.TRANS_LINEAR)
	tween.start()
	
	yield(tween, "tween_completed")
	weapon_node.show()
	reload_node.hide()
	


func _on_CursorArea_area_entered(area):
	print("enter")
	if cur_mode == MODES.LOCK:
		emit_signal("lock_area_entered", area)


func _on_CursorArea_area_exited(area):
	print("exited")
	print(area)
	print(area.get_path())
	if cur_mode == MODES.LOCK:
		emit_signal("lock_area_exited", area)
