extends Control

enum STAT {ELECTRONICS, DEFENSES, MOBILITY, ENERGY, RARM, LARM, RSHOULDER, LSHOULDER}

const CAT_PATH = "CategoryContainers/"
const LERP_WEIGHT = 5

onready var StatNodes = [get_node(CAT_PATH + "ElectronicsContainer"),
get_node(CAT_PATH + "DefensesContainer"),
get_node(CAT_PATH + "MobilityContainer"),
get_node(CAT_PATH + "EnergyContainer"),
get_node(CAT_PATH + "RArmContainer"),
get_node(CAT_PATH + "LArmContainer"),
get_node(CAT_PATH + "RShoulderContainer"),
get_node(CAT_PATH + "LShoulderContainer")]

onready var StatNodeTitles = ["Electronics",
"Defenses",
"Mobility",
"Energy",
"Right Arm",
"Left Arm",
"Right Shoulder",
"Left Shoulder"]

onready var CategoryTitle = $CategoryTitle

var current_category = 0
var compared_part = false

func _ready():
	mode_switch(0)
	
func _process(dt):
	if not compared_part:
		for container in $CategoryContainers.get_children():
			for stat in container.get_node("VBoxContainer").get_children():
				if stat.get_child_count() > 0:
					var comparison_value = stat.get_node("ComparisonValue")
					comparison_value.percent_visible = lerp(comparison_value.percent_visible, 0, LERP_WEIGHT*dt)
					if stat.has_node("ComparisonBar"):
						var comparison_bar = stat.get_node("ComparisonBar")
						var real_bar = stat.get_node("RealBar")
						comparison_bar.value = lerp(comparison_bar.value, real_bar.value, LERP_WEIGHT*dt)
					

func mode_switch (mode):
	assert(mode >= 0 and mode <= StatNodes.size() - 1, "Not a valid mode: " + str(mode))
	var target_node = StatNodes[mode]
	for child in $CategoryContainers.get_children():
		child.visible = child == target_node 
	current_category = mode 
	CategoryTitle.text = StatNodeTitles[current_category]

func _on_SwitchRight_pressed():
	current_category = ((current_category + 1) % StatNodes.size())
	mode_switch(current_category)


func _on_SwitchLeft_pressed():
	current_category = posmod(current_category - 1, StatNodes.size())
	mode_switch(current_category)

func no_comparing_part():
	pass

func set_comparing_part():
	pass
