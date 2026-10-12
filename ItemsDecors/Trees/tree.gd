extends Node2D

@onready var tree_sprite = $AnimatedSprite2D
@onready var fire_fx = $FireFX
@onready var smoke = $Smoke

@export var texture_y: int = 0

var gs

const TREE_TEXTURE_PATHS = {
	"explorer": "res://ItemsDecors/Trees/trees_explorer.png",
	"survivor": "res://ItemsDecors/Trees/trees_survivor.png",
	"king": "res://ItemsDecors/Trees/trees_king.png"
}


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

	# Charge uniquement la texture correspondant à la difficulté actuelle
	var texture_path: String = TREE_TEXTURE_PATHS.get(gs.difficulty, "")

	if texture_path.is_empty():
		push_error("Difficulté inconnue pour l'arbre : " + str(gs.difficulty))
		return

	var difficulty_texture: Texture2D = load(texture_path)

	if difficulty_texture == null:
		push_error("Impossible de charger la texture : " + texture_path)
		return

	# Le Banana_tree occupe la 4e ligne de la texture : Y = 3000
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = difficulty_texture
	atlas_texture.region = Rect2(0, texture_y, 750, 1000)

	# Construit une seule animation avec une seule frame
	var frames := SpriteFrames.new()
	frames.add_animation("tree")
	frames.add_frame("tree", atlas_texture)

	tree_sprite.sprite_frames = frames
	tree_sprite.animation = "tree"

	match gs.difficulty:
		"explorer":
			tree_sprite.modulate = Color("ffffffff")

		"survivor":
			tree_sprite.modulate = Color("f2a11fff")
			smoke.visible = true

		"king":
			tree_sprite.modulate = Color("2b32aaff")
			fire_fx.visible = true
			smoke.visible = true


func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.can_climb = true


func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		body.can_climb = false
