extends Camera2D

@export var joueur : Node2D

func _process(_delta):
	if joueur:
		global_position = joueur.global_position
