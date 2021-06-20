extends Node

onready var g = "res://game/mecha/Graphs.gd"

var connections = []
var id

func _ready():
	pass


func add_connection(origin, final, condition):
	connections.push_back([final, condition])
	

func get_connections():
	return connections

	
func get_valid_connections():
	var valid_connections = []
	for connection in connections:
		if connection[1]:
			valid_connections.insert(connection)
	return valid_connections


