extends Node2D

var rune_scene = preload("res://ItemsDecors/Totem/Runes/rune.tscn")

var rune_spawn
var stages = []

var game_state = null
var rune_spawned = false


func _ready():
	rune_spawn = $RuneSpawn
	stages = [$Stage1, $Stage2, $Stage3, $Stage4]

	game_state = get_node_or_null("/root/GameState")

	if game_state:
		# 1) Affiche l'étape correspondant à l'état actuel
		update_totem_stage()

		# 2) Si toutes les graines sont déjà collectées
		# → étape 4 + spawn rune immédiat
		if game_state.total_seeds_in_level > 0 and game_state.collected_seeds >= game_state.total_seeds_in_level:
			update_sprite(4)
			spawn_rune()

		# 3) Branche le signal sans doublon
		var cb = Callable(self, "on_all_seeds_collected")

		if not game_state.is_connected("all_seeds_collected", cb):
			game_state.connect("all_seeds_collected", cb)


# ============================================================================
#                         ÉTAT VISUEL DU TOTEM
# ============================================================================

func update_totem_stage():
	if not game_state:
		return

	if game_state.total_seeds_in_level == 0:
		return

	var collected = game_state.collected_seeds
	var total = game_state.total_seeds_in_level

	if total <= 0:
		return

	var percent = float(collected) / float(total)

	# 0..3
	var stage_index = int(floor(percent * 4.0))

	if stage_index < 0:
		stage_index = 0

	if stage_index > 3:
		stage_index = 3

	# update_sprite attend 1..4
	update_sprite(stage_index + 1)


# ============================================================================
#                         SPRITE DU TOTEM
# ============================================================================

func update_sprite(stage_index):
	for i in range(stages.size()):
		stages[i].visible = (i == stage_index - 1)


# ============================================================================
#                         TOUTES LES GRAINES
# ============================================================================

func on_all_seeds_collected():
	if game_state:
		game_state.lvl1_totem_done = true

		if game_state.hud:
			game_state.hud.update_lvl1_checklist()

	update_sprite(4)

	spawn_rune()


# ============================================================================
#                         SPAWN DE LA RUNE
# ============================================================================

func spawn_rune():
	if rune_spawned:
		return

	rune_spawned = true

	if not rune_scene:
		push_error("TOTEM : rune_scene non assignée")
		return

	if not rune_spawn:
		push_error("TOTEM : RuneSpawn introuvable")
		return

	var rune = rune_scene.instantiate()

	rune.global_position = rune_spawn.global_position
	rune.z_index = 20

	# Ajoute la rune directement dans le niveau courant.
	var parent = null

	if game_state and game_state.current_level:
		parent = game_state.current_level
	else:
		parent = get_tree().current_scene

	if parent:
		parent.call_deferred("add_child", rune)
