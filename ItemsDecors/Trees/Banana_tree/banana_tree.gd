extends Node2D

@onready var tree_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fire_fx: Node2D = $FireFX

var gs


func _ready() -> void:
	gs = get_node("/root/GameState")
	_apply_difficulty()


func _apply_difficulty() -> void:
	match gs.difficulty:
		"explorer":
			tree_sprite.play("texture_explorer")
			fire_fx.visible = false

		"survivor":
			tree_sprite.play("texture_survivor")
			fire_fx.visible = false

		"king":
			tree_sprite.play("texture_king")
			fire_fx.visible = true


func _on_area_2d_body_entered(body) -> void:
	if body.is_in_group("Player"):
		body.can_climb = true


func _on_area_2d_body_exited(body) -> void:
	if body.is_in_group("Player"):
		body.can_climb = false
