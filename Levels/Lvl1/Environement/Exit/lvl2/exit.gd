extends Area2D

const MAIN_MENU_PATH := "res://Levels/Lvl0/lvl_0.tscn"
const LEVEL_PATH := "res://Levels/Lvl1/lvl_1.tscn"

var is_unlocked: bool = false
var already_faded: bool = false
var exit_in_progress: bool = false


# ============================================================================
#                              INITIALISATION
# ============================================================================

func _ready():
	$CloseSprite.visible = true
	$CloseSprite.modulate = Color.WHITE

	$OpenSprite.visible = false

	await get_tree().process_frame

	var gs = get_node_or_null("/root/GameState")

	if not gs:
		push_error("EXIT : GameState introuvable")
		return

	if not gs.is_connected(
		"key_collected",
		Callable(self, "on_key_collected")
	):
		gs.connect(
			"key_collected",
			Callable(self, "on_key_collected")
		)

	is_unlocked = gs.has_key

	update_visual(is_unlocked)


# ============================================================================
#                              POPUP
# ============================================================================

func show_info_popup(txt: String):
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

func update_visual(unlocked: bool):
	$CloseSprite.visible = not unlocked
	$OpenSprite.visible = unlocked


func on_key_collected():
	is_unlocked = true

	var gs = get_node_or_null("/root/GameState")

	if (
		gs
		and gs.current_level
		and gs.current_level.has_method("focus_camera_on_exit_and_fade")
	):
		await gs.current_level.focus_camera_on_exit_and_fade()

	update_visual(true)


# ============================================================================
#                         ENTRÉE DU JOUEUR
# ============================================================================

func _on_body_entered(body):
	if body.name != "Player":
		return

	# Empêche plusieurs déclenchements de la sortie.
	if exit_in_progress:
		return

	if not is_unlocked:
		show_info_popup(
			"🔑 Il te faut la clé pour ouvrir la porte !"
		)

		$LockedSound.play()

		return

	exit_in_progress = true

	var anim_player = body.get_node_or_null("Node2D/Anim")

	if anim_player and anim_player.has_animation("door"):
		body.animation_locked = true

		anim_player.play("door")

		await anim_player.animation_finished

	body.set_physics_process(false)

	await _finish_level()


# ============================================================================
#                         FIN DU NIVEAU
# ============================================================================

func _finish_level():
	var gs = get_node_or_null("/root/GameState")

	if not gs:
		push_error("EXIT : GameState introuvable")
		return

	var completed_difficulty: String = gs.difficulty

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
	# On mémorise le dialogue AVANT de modifier la difficulté.
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
	#
	# Important :
	# CinematicToucanFinal n'est plus un niveau de progression.
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
#                         ANIMATION OUVERTURE
# ============================================================================

func play_fade():
	if already_faded:
		return

	already_faded = true

	$OpenSprite.visible = true
	$OpenSprite.modulate.a = 1.0

	$CloseSprite.visible = true
	$CloseSprite.modulate.a = 1.0

	await shake_temple(0.4, 4.0)
	await fade_close_sprite()

	$CloseSprite.visible = false


# ============================================================================
#                         SHAKE TEMPLE
# ============================================================================

func shake_temple(
	duration: float = 0.3,
	intensity: float = 3.0
):
	var original_pos := position
	var time_elapsed := 0.0
	var step := 0.02

	while time_elapsed < duration:
		var offset := Vector2(
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
	var duration := 1.0
	var steps := 20
	var delay := duration / steps

	for i in range(steps + 1):
		var alpha := 1.0 - float(i) / steps

		$CloseSprite.modulate.a = alpha

		await get_tree().create_timer(delay).timeout
