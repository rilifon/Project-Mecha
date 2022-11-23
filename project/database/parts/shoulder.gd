extends Node


enum SIDE {LEFT, RIGHT, SINGLE}

export var part_name : String
export var manufacturer_name : String
export var image : Texture
export var shield := 10


func get_image(side):
	if side == SIDE.LEFT:
		return $ShoulderLeft.texture
	elif side == SIDE.RIGHT:
		return $ShoulderRight.texture
	else:
		push_error("Not a valid side:" + str(side))

func get_collision(side):
	if side == SIDE.LEFT:
		return $ShoulderLeft/Collision.polygon
	elif side == SIDE.RIGHT:
		return $ShoulderRight/Collision.polygon
	else: 
		push_error("Not a valid side:" + str(side))
