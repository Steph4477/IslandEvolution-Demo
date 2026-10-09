extends Node2D

@onready var tree_sprite = $AnimatedSprite2D
@onready var fire_fx = $FireFX
@onready var smoke = $Smoke

var gs


func _ready():
	gs = get_node("/root/GameState")

	# Attend que le Lvl1 ait initialisé la difficulté
	await get_tree().process_frame

	_apply_difficulty()


func _apply_difficulty():
	# Reset
	fire_fx.visible = false
	smoke.visible = false
	tree_sprite.modulate = Color.WHITE

	match gs.difficulty:
		"explorer":
			tree_sprite.animation = "texture_explorer"
			tree_sprite.modulate = Color("ffffffff")

		"survivor":
			tree_sprite.animation = "texture_survivor"
			tree_sprite.modulate = Color("f2a11fff")
			smoke.visible = true

		"king":
			tree_sprite.animation = "texture_king"
			tree_sprite.modulate = Color("2b32aaff")
			fire_fx.visible = true
			smoke.visible = true


func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.can_climb = true


func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		body.can_climb = false
