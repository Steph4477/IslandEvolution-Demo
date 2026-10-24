extends Node2D

var gs

@onready var explorer = $Area2D/Explorer
@onready var survivor = $Area2D/Survivor
@onready var king = $Area2D/King


func _ready():
	gs = get_node("/root/GameState")

	explorer.visible = false
	survivor.visible = false
	king.visible = false

	print("RUNE SPAWN - difficulté : ", gs.difficulty)

	match gs.difficulty:
		"explorer":
			explorer.visible = true

		"survivor":
			survivor.visible = true

		"king":
			king.visible = true


func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		gs.has_rune = true
		gs.emit_signal("rune_collected")
		queue_free()
