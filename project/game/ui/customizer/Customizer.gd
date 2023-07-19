extends Control
const ITEMFRAME = preload("res://game/ui/customizer/ItemFrame.tscn")
const LERP_WEIGHT = 5

enum SIDE {LEFT, RIGHT, SINGLE}
enum STAT {ELECTRONICS, DEFENSES, MOBILITY, ENERGY, RARM, LARM, RSHOULDER, LSHOULDER}

@onready var PartList = $PartListContainer/VBoxContainer
@onready var CategorySelectedUI = $CategorySelectedUI
@onready var CategoryButtons = $CategoryButtons
@onready var PartCategories = $PartCategories
@onready var DisplayMecha = $Mecha
@onready var ComparisonMecha = $ComparisonMecha
#onready var StatBars = $Statbars
@onready var Statcard = $Statcard
@onready var LoadScreen = $LoadScreen
@onready var CommandLine = $CommandLine

var category_visible = false
var comparing_part = false
var type_name
var current_group

func _ready():
	$LoadScreen.shopping_mode = false
	if Profile.stats.current_mecha:
		DisplayMecha.set_parts_from_design(Profile.stats.current_mecha)
		ComparisonMecha.set_parts_from_design(Profile.stats.current_mecha)
	else:
		default_loadout()
	#$Statbars.update_stats(DisplayMecha)
	update_weight()
	DisplayMecha.global_rotation = 0
	LoadScreen.connect("load_pressed",Callable(self,"_LoadScreen_on_load_pressed"))
	for child in $TopBar.get_children():
		child.reset_comparison(DisplayMecha)
	shoulder_weapon_check()

func _process(dt):
	if not comparing_part:
		$WeightComparisonBar.value = lerp($WeightComparisonBar.value, $WeightBar.value, LERP_WEIGHT*dt)
		$WeightComparisonBar.max_value = lerp($WeightComparisonBar.max_value, $WeightBar.max_value, LERP_WEIGHT*dt)
	else:
		$WeightComparisonBar.value = lerp($WeightComparisonBar.value, ComparisonMecha.get_stat("weight"), LERP_WEIGHT*dt)
		$WeightComparisonBar.max_value = lerp($WeightComparisonBar.max_value, ComparisonMecha.get_stat("weight_capacity"), LERP_WEIGHT*dt)

func _input(event):
	if event.is_action_pressed("toggle_fullscreen"):
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (not ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))) else Window.MODE_WINDOWED
		Profile.set_option("fullscreen", ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)), true)
		if not ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)):
			await get_tree().process_frame
			get_window().size = Profile.WINDOW_SIZES[Profile.get_option("window_size")]
			get_window().position = Vector2(0,0)


func default_loadout():
	DisplayMecha.set_core("MSV-L3J-C")
	DisplayMecha.set_generator("type_1")
	DisplayMecha.set_chipset("type_1")
	DisplayMecha.set_head("MSV-L3J-H")
	DisplayMecha.set_chassis("MSV-L3J-L")
	DisplayMecha.set_arm_weapon("MA-L127", SIDE.LEFT)
	DisplayMecha.set_arm_weapon("MA-L127", SIDE.RIGHT)
	DisplayMecha.set_shoulder_weapon("CL1-Shoot", SIDE.RIGHT)
	DisplayMecha.set_shoulder_weapon(false, SIDE.LEFT)
	DisplayMecha.set_shoulders("MSV-L3J-SG")
	
	ComparisonMecha.set_core("MSV-L3J-C")
	ComparisonMecha.set_generator("type_1")
	ComparisonMecha.set_chipset("type_1")
	ComparisonMecha.set_head("MSV-L3J-H")
	ComparisonMecha.set_chassis("MSV-L3J-L")
	ComparisonMecha.set_arm_weapon("MA-L127", SIDE.LEFT)
	ComparisonMecha.set_arm_weapon("MA-L127", SIDE.RIGHT)
	ComparisonMecha.set_shoulder_weapon("CL1-Shoot", SIDE.RIGHT)
	ComparisonMecha.set_shoulder_weapon(false, SIDE.LEFT)
	ComparisonMecha.set_shoulders("MSV-M2-SG")
	
	shoulder_weapon_check()
	update_weight()


func show_category_button(parts, selected):
	category_visible = false
	PartList.visible = false
	for child in PartList.get_children():
		PartList.remove_child(child)
	for category in PartCategories.get_children():
		category.visible = (category == parts)
		for part in category.get_children():
			part.visible = true
			part.button_pressed = false
	for child in CategorySelectedUI.get_children():
		child.visible = (child == selected)


func _on_Category_pressed(type,group,side = false):
	CommandLine.display("/inventory_parser --" + str(type))
	current_group = group
	var group_node = PartCategories.get_node(group)
	Statcard.visible = false
	type_name = type
	if side:
		type_name = type + "_" + side
	if category_visible == false:
		category_visible = true
		PartList.visible = true
		for child in group_node.get_children():
			if child.name != type_name:
				child.visible = false
				child.button_pressed = false
		var parts = PartManager.get_parts(type)
		for child in PartList.get_children(): #Clear PartList
			PartList.remove_child(child)
		var inventory = Profile.get_inventory()
		for part_key in inventory.keys(): #Parsing through a dictionary using super.values()
			if parts.has(part_key):
				var part = parts[part_key]
				var item = ITEMFRAME.instantiate()
				item.setup(part, false, inventory.get(part_key))
				if DisplayMecha.get(type_name):
					if DisplayMecha.get(type_name) == part:
						item.get_button().disabled = true
						item.is_disabled = true
				PartList.add_child(item)
				item.get_button().connect("pressed",Callable(self,"_on_ItemFrame_pressed").bind(part_key,type,side,item))
				item.get_button().connect("mouse_entered",Callable(self,"_on_ItemFrame_mouse_entered").bind(part_key,type,side,item))
				item.get_button().connect("mouse_exited",Callable(self,"_on_ItemFrame_mouse_exited").bind(part_key,type,side,item))
		if $CurrentItemFrame.get_button().is_connected("pressed",Callable(self,"unequip_part")):
			$CurrentItemFrame.get_button().disconnect("pressed",Callable(self,"unequip_part"))
		if DisplayMecha.get(type_name):
			$CurrentItemFrame.visible = true
			$CurrentItemFrame.setup(DisplayMecha.get(type_name), false, false)
			$CurrentItemFrame.get_button().connect("pressed",Callable(self,"unequip_part").bind(type_name,side))
	else:
		category_visible = false
		$CurrentItemFrame.visible = false
		for child in group_node.get_children():
			child.visible = true
		for child in PartList.get_children(): #Clear PartList
			PartList.remove_child(child)
		PartList.visible = false


func _on_HardwareButton_pressed():
	CommandLine.display("/inventory_category --hardware")
	show_category_button($PartCategories/Hardware, $CategorySelectedUI/Hardware)


func _on_WetwareButton_pressed():
	CommandLine.display("/inventory_category --wetware")
	show_category_button($PartCategories/Wetware, $CategorySelectedUI/Wetware)


func _on_EquipmentButton_pressed():
	CommandLine.display("/inventory_category --equipment")
	show_category_button($PartCategories/Equipment, $CategorySelectedUI/Equipment)


func _on_ItemFrame_pressed(part_name,type,side,item):
	if item.is_disabled == true:
		if type == "core":
			$MissingPartsScroll/MissingParts.text = ""
			return
		item.get_button().disabled = false
		item.is_disabled = false
		part_name = false
	else:
		for child in item.get_parent().get_children():
			child.get_button().disabled = false
			child.is_disabled = false
		item.is_disabled = true
		item.get_button().disabled = true
		item.get_button().button_pressed = false
	if side:
		side = DisplayMecha.SIDE.LEFT if side == "left" else DisplayMecha.SIDE.RIGHT
		DisplayMecha.callv("set_" + str(type), [part_name,side])
		ComparisonMecha.callv("set_" + str(type), [part_name,side])
	else:
		DisplayMecha.callv("set_" + str(type), [part_name])
		ComparisonMecha.callv("set_" + str(type), [part_name])
	Profile.remove_from_inventory(part_name)
	var inventory = Profile.get_inventory()
	item.get_node("QuantityLabel").text = str(inventory.get(part_name))
	update_weight()
	shoulder_weapon_check()
	comparing_part = false
	if $CurrentItemFrame.get_button().is_connected("pressed",Callable(self,"unequip_part")):
		$CurrentItemFrame.get_button().disconnect("pressed",Callable(self,"unequip_part"))
	$CurrentItemFrame.visible = true
	$CurrentItemFrame.setup(item.current_part, false, false)
	$CurrentItemFrame.get_button().connect("pressed",Callable(self,"unequip_part").bind(type_name,side))


func _on_ItemFrame_mouse_entered(part_name,type,side,item):
	if item.is_disabled == true:
		item.get_button().disabled = false
	if side:
		side = DisplayMecha.SIDE.LEFT if side == "left" else DisplayMecha.SIDE.RIGHT
		ComparisonMecha.callv("set_" + str(type), [part_name,side])
	else:
		ComparisonMecha.callv("set_" + str(type), [part_name])
	#StatBars.set_comparing_part(ComparisonMecha)
	for child in $TopBar.get_children():
		child.set_comparing_part(DisplayMecha,ComparisonMecha)
	var current_part = DisplayMecha.get(type_name)
	var new_part = ComparisonMecha.get(type_name)
	if ComparisonMecha.is_overweight():
		$Overweight.visible = true
	else:
		$Overweight.visible = false
	Statcard.display_part_stats(current_part, new_part, type_name)
	Statcard.visible = true
	comparing_part = true


func shoulder_weapon_check():
	var core
	if DisplayMecha.build.core:
		core = DisplayMecha.build.core
	else:
		$PartCategories/Equipment/shoulder_weapon_left.disabled = true
		$PartCategories/Equipment/shoulder_weapon_right.disabled = true
		return
	if not core.has_left_shoulder:
		$PartCategories/Equipment/shoulder_weapon_left.disabled = true
	else:
		$PartCategories/Equipment/shoulder_weapon_left.disabled = false
	if not core.has_right_shoulder:
		$PartCategories/Equipment/shoulder_weapon_right.disabled = true
	else:
		$PartCategories/Equipment/shoulder_weapon_right.disabled = false


func is_build_valid():
	var build_valid = true
	var missing_parts : String
	for part in ["head", "core", "shoulders", "generator",\
				"chipset", "chassis", "thruster", "shoulders"]:
		if not DisplayMecha.build[part]:
			build_valid = false
			missing_parts = missing_parts + "WARN: " + part + " "
	if not build_valid:
		$MissingPartsScroll/MissingParts.text = missing_parts
		$MissingPartsScroll/MissingParts.visible = true
	else:
		$MissingPartsScroll/MissingParts.visible = false
	return build_valid

func _on_ItemFrame_mouse_exited(_part_name,_type,_side, item):
	if item.is_disabled == true:
		item.get_button().disabled = true
	#StatBars.reset_comparing_part()
	for child in $TopBar.get_children():
		child.reset_comparison(DisplayMecha)
	comparing_part = false
	if DisplayMecha.is_overweight():
		$Overweight.visible = true
	else:
		$Overweight.visible = false

func update_weight():
	$WeightBar.max_value = DisplayMecha.get_stat("weight_capacity")
	$WeightBar.value = DisplayMecha.get_stat("weight")
	$CurrentWeightLabel.text = str(DisplayMecha.get_stat("weight")) 
	$MaxWeightLabel.text = str(DisplayMecha.get_stat("weight_capacity"))


func _on_Save_pressed():
	FileManager.save_mecha_design(DisplayMecha, "test")


func _on_Exit_pressed():
	if is_build_valid():
		Profile.set_stat("current_mecha", DisplayMecha.get_design_data())
		TransitionManager.transition_to("res://game/start_menu/StartMenuDemo.tscn", "Rebooting System...")
	else:
		print("Build invalid")

func _on_Load_pressed():
	$LoadScreen.visible = true

func _LoadScreen_on_load_pressed(design):
	DisplayMecha.set_parts_from_design(design)
	ComparisonMecha.set_parts_from_design(design)
	shoulder_weapon_check()
	update_weight()

func unequip_part(_type_name, side):
	Profile.add_to_inventory($CurrentItemFrame.current_part.part_id)
	if side:
		side = DisplayMecha.SIDE.LEFT if side == "left" else DisplayMecha.SIDE.RIGHT
		if "arm_weapon" in _type_name:
			_type_name = "arm_weapon" 
		if "shoulder_weapon" in _type_name:
			_type_name = "shoulder_weapon" 
		DisplayMecha.callv("set_" + str(_type_name), [null,side])
		ComparisonMecha.callv("set_" + str(_type_name), [null,side])
	else:
		DisplayMecha.callv("set_" + str(_type_name), [null])
		ComparisonMecha.callv("set_" + str(_type_name), [null])
	$CurrentItemFrame.visible = false
	shoulder_weapon_check()
	category_visible = false
	$CurrentItemFrame.visible = false
	for child in PartList.get_children(): #Clear PartList
		if child.current_part == $CurrentItemFrame.current_part:
			child.get_node("QuantityLabel").text = str(Profile.get_inventory().get($CurrentItemFrame.current_part.part_id))
