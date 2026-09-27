extends Node2D                          

var cam
var player
var gs

func _ready():
	gs = get_node("/root/GameState")

	await get_tree().process_frame

	player = gs.player
	cam = player.get_node("Camera2D")
	cam.limit_right = 9500
	cam.limit_top = -300
	cam.limit_bottom = 1700
