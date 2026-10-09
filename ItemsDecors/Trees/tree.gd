extends Node2D

@onready var tree_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fire_fx: Node2D = $FireFX
@onready var smoke: Node2D = $Smoke

var gs


func _ready() -> void:
	gs = get_node("/root/GameState")

	# Attend que le Lvl1 ait initialisé la difficulté
	await get_tree().process_frame

	_apply_difficulty()


func _apply_difficulty() -> void:
	print("TREE DIFFICULTY : ", gs.difficulty)

	# Reset
	fire_fx.visible = false
	smoke.visible = false
	tree_sprite.modulate = Color.WHITE

	match gs.difficulty:
		"explorer":
			tree_sprite.animation = "texture_explorer"
			tree_sprite.modulate = Color("ffffffff")

			print("TREE : EXPLORER")

		"survivor":
			tree_sprite.animation = "texture_survivor"
			tree_sprite.modulate = Color("f2a11fff")
			smoke.visible = true

			print("TREE : SURVIVOR")

		"king":
			tree_sprite.animation = "texture_king"
			tree_sprite.modulate = Color("2b32aaff")
			fire_fx.visible = true
			smoke.visible = true

			print("TREE : KING")

		_:
			push_warning(
				"TREE : difficulté inconnue : " + str(gs.difficulty)
			)


func _on_area_2d_body_entered(body) -> void:
	if body.is_in_group("Player"):
		body.can_climb = true


func _on_area_2d_body_exited(body) -> void:
	if body.is_in_group("Player"):
		body.can_climb = false
