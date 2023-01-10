extends CanvasLayer


func _ready():
	reset()


func reset():
	$ViewportContainer.visible = false


func killed():
	MouseManager.show_cursor()
	ShaderEffects.reset_shader_effect("gameover")
	$ViewportContainer.visible = true


func _on_ReturnButton_pressed():
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://game/start_menu/StartMenu.tscn")
