extends Node2D

@onready var anim = $AnimationPlayer
@onready var toucan = $Toucan
@onready var box = $Box
@onready var text = $Box/MarginContainer/Text

# ============================================================================
#                              RÉGLAGES
# ============================================================================

@export var lines = []

@export var chars_per_sec = 30
@export var pause_between_lines = 1.0
@export var hide_when_done = true
@export var dialogue_delay = 4.0


# ============================================================================
#                              VARIABLES
# ============================================================================

var player = null

var line_index = -1
var full_line = ""
var shown_chars = 0
var writing = false
var accum = 0.0
var pause_left = 0.0


# ============================================================================
#                              INITIALISATION
# ============================================================================

func _ready():
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("Player")

	if player == null:
		print("❌ CINEMATIC TOUCAN FINAL : Player introuvable")
	else:
		player.disable_controls()

	var game_state = get_node_or_null("/root/GameState")

	if game_state:
		print("🎯 DIFFICULTY TOUCAN = [", game_state.difficulty, "]")
		match game_state.difficulty:

			# ================================================================
			# EXPLORATEUR -> SURVIVANT + DOUBLE JUMP
			# ================================================================
			"explorer":
				lines = [
					"Bravo, Moko !",
					"Tu as triomphé de la Jungle.",
					"Mais l’île va évoluer…",
					"Toi aussi : tu peux tester le Double Saut !",
					"Mode Survivant débloqué !"
				]

			# ================================================================
			# SURVIVANT -> ROI + FIRE
			# ================================================================
			"survivor":
				lines = [
					"Impressionnant, Moko !",
					"Tu as survécu à une île bien plus dangereuse.",
					"Mais elle peut encore évoluer…",
					"Tu peux tester le pouvoir du Feu !",
					"Mode Roi de l’île débloqué !"
				]

			# ================================================================
			# ROI DE L'ÎLE -> FIN DEMO
			# ================================================================
			"king":
				lines = [
					"Tu l’as fait, Moko !",
					"L’île t’a tout donné.",
					"Tu as affronté sa forme ultime…",
					"Et tu es toujours debout.",
					"Tu es le Roi de l’île !"
				]

	start_cinematic()

	await get_tree().create_timer(dialogue_delay).timeout

	start()


# ============================================================================
#                              CINÉMATIQUE
# ============================================================================

func start_cinematic():
	box.visible = false
	toucan.visible = true

	anim.play("intro")


# ============================================================================
#                              DIALOGUE
# ============================================================================

func start(new_lines = null):
	print("🟢 START DIALOGUE")
	print("LINES = ", lines)
	print("BOX AVANT = ", box.visible)

	if new_lines != null:
		lines = new_lines.duplicate()

	line_index = 0

	visible = true
	box.visible = true

	print("BOX APRES = ", box.visible)

	set_process(true)

	_start_line()


func _start_line():
	if line_index >= lines.size():
		_end_dialogue()
		return

	full_line = str(lines[line_index])

	shown_chars = 0
	accum = 0.0
	writing = true
	pause_left = 0.0

	_render()


func _process(delta):
	if not box.visible:
		return

	if writing:
		accum += delta

		var step = int(accum * chars_per_sec)

		if step > 0:
			accum -= float(step) / float(chars_per_sec)
			shown_chars += step

			if shown_chars >= full_line.length():
				shown_chars = full_line.length()
				writing = false
				pause_left = pause_between_lines

			_render()

	elif pause_left > 0.0:
		pause_left -= delta

		if pause_left <= 0.0:
			line_index += 1
			_start_line()


func _render():
	text.text = full_line.substr(0, shown_chars)


# ============================================================================
#                              FIN
# ============================================================================

func _end_dialogue():
	if hide_when_done:
		box.visible = false

	set_process(false)

	print("🦜 Cinématique finale Toucan terminée")

	var game_state = get_node_or_null("/root/GameState")

	if game_state:

		print("DIFFICULTY AVANT VALIDATION : ", game_state.difficulty)
		print("EXPLORER : ", game_state.explorer_unlocked)
		print("SURVIVOR : ", game_state.survivor_unlocked)
		print("KING : ", game_state.king_unlocked)

		# ================================================================
		# EXPLORATEUR -> SURVIVANT + DOUBLE JUMP
		# SURVIVANT   -> ROI + FIRE
		# ================================================================
		if game_state.difficulty == "explorer" or game_state.difficulty == "survivor":
			game_state.unlock_next_difficulty()

		# ================================================================
		# ROI DE L'ÎLE -> FIN DE LA DEMO
		# ================================================================
		elif game_state.difficulty == "king":
			print("🏆 VICTOIRE MODE ROI DE L'ILE")

			if game_state.has_method("validate_current_difficulty"):
				game_state.validate_current_difficulty()

	# ================================================================
	# RETOUR MENU
	# ================================================================
	if game_state and game_state.has_method("load_level"):
		await game_state.load_level("res://Levels/Lvl0/lvl_0.tscn")
