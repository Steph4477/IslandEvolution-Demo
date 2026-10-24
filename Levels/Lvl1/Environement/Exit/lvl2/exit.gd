extends Area2D

const MAIN_MENU_PATH = "res://Levels/Lvl0/lvl_0.tscn"
const LEVEL_PATH = "res://Levels/Lvl1/lvl_1.tscn"

var is_unlocked = false
var already_reacted = false
var exit_in_progress = false

signal rune_activated

# ============================================================================
#                              INITIALISATION
# ============================================================================

func _ready():
	$CloseSprite.visible = true
	$CloseSprite.modulate = Color.WHITE

	$OpenSprite.visible = false
	$OpenSprite.modulate = Color.WHITE

	await get_tree().process_frame

	var gs = get_node_or_null("/root/GameState")

	if not gs:
		push_error("EXIT : GameState introuvable")
		return

	is_unlocked = false

	update_visual(false)
	update_rune_symbols()


# ============================================================================
#                              POPUP
# ============================================================================

func show_info_popup(txt):
	var popup_scene = preload(
		"res://Interface/Popup/Info_popup/info_popup.tscn"
	)

	var popup = popup_scene.instantiate()

	get_tree().root.add_child(popup)

	await get_tree().process_frame

	popup.show_info(txt)


# ============================================================================
#                              PORTE
# ============================================================================

func update_visual(unlocked):
	$CloseSprite.visible = not unlocked
	$OpenSprite.visible = unlocked


func open_temple():
	is_unlocked = true

	$CloseSprite.visible = false
	$OpenSprite.visible = true


func close_temple():
	is_unlocked = false

	$CloseSprite.visible = true
	$CloseSprite.modulate.a = 1.0

	$OpenSprite.visible = false


# ============================================================================
#                      RÉACTION DU TEMPLE À LA RUNE
# ============================================================================

func play_temple_reaction():
	if already_reacted:
		return

	already_reacted = true

	var gs = get_node_or_null("/root/GameState")

	if not gs:
		push_error("EXIT : GameState introuvable")
		return

	match gs.difficulty:
		"explorer":
			await shake_temple(0.4, 4.0)
			close_temple()

		"survivor":
			await shake_temple(0.7, 7.0)
			close_temple()

		"king":
			await shake_temple(1.0, 10.0)
			await open_temple_with_fade()


# ============================================================================
#                         ANCIENNE AREA EXIT
# ============================================================================

func _on_body_entered(body):
	if body.name != "Player":
		return

	# Cette Area ne termine plus le niveau.
	# RunExit gère désormais la fin du run.


# ============================================================================
#                         FIN DU NIVEAU
# ============================================================================

func _finish_level():
	var gs = get_node_or_null("/root/GameState")

	if not gs:
		push_error("EXIT : GameState introuvable")
		return

	var completed_difficulty = gs.difficulty

	print("======================================")
	print("FIN DU NIVEAU")
	print("DIFFICULTÉ TERMINÉE : ", completed_difficulty)
	print("======================================")

	# ------------------------------------------------------------------------
	# SCORE
	# ------------------------------------------------------------------------

	gs.score_system.calculate_stars()
	gs.show_score_screen()

	await get_tree().create_timer(5.0).timeout

	# ------------------------------------------------------------------------
	# DIALOGUE
	# ------------------------------------------------------------------------

	gs.pending_end_dialogue = completed_difficulty

	# ------------------------------------------------------------------------
	# PROGRESSION
	# ------------------------------------------------------------------------

	match completed_difficulty:

		"explorer", "survivor":
			if gs.has_method("unlock_next_difficulty"):
				gs.unlock_next_difficulty()
			else:
				push_error(
					"EXIT : unlock_next_difficulty() introuvable"
				)

		"king":
			if gs.has_method("validate_current_difficulty"):
				gs.validate_current_difficulty()
			else:
				push_error(
					"EXIT : validate_current_difficulty() introuvable"
				)

		_:
			push_error(
				"EXIT : difficulté inconnue : "
				+ completed_difficulty
			)

			return

	# ------------------------------------------------------------------------
	# PROCHAIN NIVEAU
	# ------------------------------------------------------------------------

	gs.unlocked_level_path = LEVEL_PATH

	gs.save_progress()

	# ------------------------------------------------------------------------
	# RETOUR MENU
	# ------------------------------------------------------------------------

	print(
		"🦜 Dialogue menu en attente : ",
		gs.pending_end_dialogue
	)

	await gs.load_level(MAIN_MENU_PATH)


# ============================================================================
#                         OUVERTURE DU TEMPLE
# ============================================================================

func open_temple_with_fade():
	$OpenSprite.visible = true
	$OpenSprite.modulate.a = 1.0

	$CloseSprite.visible = true
	$CloseSprite.modulate.a = 1.0

	await fade_close_sprite()

	$CloseSprite.visible = false

	is_unlocked = true


# ============================================================================
#                         SHAKE TEMPLE
# ============================================================================

func shake_temple(duration = 0.3, intensity = 3.0):
	var original_pos = position
	var time_elapsed = 0.0
	var step = 0.02

	while time_elapsed < duration:
		var offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)

		position = original_pos + offset

		await get_tree().create_timer(step).timeout

		time_elapsed += step

	position = original_pos


# ============================================================================
#                         FADE PORTE
# ============================================================================

func fade_close_sprite():
	var duration = 1.0
	var steps = 20
	var delay = duration / steps

	for i in range(steps + 1):
		var alpha = 1.0 - float(i) / steps

		$CloseSprite.modulate.a = alpha

		await get_tree().create_timer(delay).timeout


# ============================================================================
#                         SYMBOLES DES RUNES
# ============================================================================

func update_rune_symbols():
	var gs = get_node_or_null("/root/GameState")

	if not gs:
		push_error("EXIT : GameState introuvable")
		return

	# Explorer
	$RuneSymbols/ExplorerOff.visible = not gs.explorer_unlocked
	$RuneSymbols/ExplorerOn.visible = gs.explorer_unlocked

	# Survivor
	$RuneSymbols/SurvivorOff.visible = not gs.survivor_unlocked
	$RuneSymbols/SurvivorOn.visible = gs.survivor_unlocked

	# King
	$RuneSymbols/KingOff.visible = not gs.king_unlocked
	$RuneSymbols/KingOn.visible = gs.king_unlocked

	print("======================================")
	print("SYMBOLES TEMPLE")
	print("EXPLORER : ", gs.explorer_unlocked)
	print("SURVIVOR : ", gs.survivor_unlocked)
	print("KING : ", gs.king_unlocked)
	print("======================================")

func activate_current_rune():
	var gs = get_node_or_null("/root/GameState")

	if not gs:
		return

	match gs.difficulty:
		"explorer":
			$RuneSymbols/ExplorerOff.visible = false
			$RuneSymbols/ExplorerOn.visible = true

		"survivor":
			$RuneSymbols/SurvivorOff.visible = false
			$RuneSymbols/SurvivorOn.visible = true

		"king":
			$RuneSymbols/KingOff.visible = false
			$RuneSymbols/KingOn.visible = true


# ============================================================================
#                         RUN EXIT
# ============================================================================

func _on_run_exit_body_entered(body):
	if body.name != "Player":
		return

	if exit_in_progress:
		return

	var gs = get_node("/root/GameState")

	if not gs.has_rune:
		return

	exit_in_progress = true

	body.disable_controls()

	gs.has_rune = false

	activate_current_rune()

	rune_activated.emit()
