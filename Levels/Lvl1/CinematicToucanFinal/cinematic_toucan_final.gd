extends Node2D

@onready var toucan = $Toucan
@onready var toucan_anim = $Toucan/AnimationPlayer

@onready var moko = $Moko
@onready var moko_anim = $Moko/AnimationPlayer

@onready var box = $Box
@onready var text = $Box/MarginContainer/Text

# ============================================================================
#                              RÉGLAGES
# ============================================================================

@export var lines = []

@export var chars_per_sec = 30
@export var pause_between_lines = 2.0
@export var hide_when_done = true
@export var dialogue_delay = 4.0

@export_category("TEST SCÈNE ISOLÉE")
@export_enum("game", "explorer", "survivor", "king")
var test_difficulty: String = "game"
var cinematic_difficulty: String = ""

# ============================================================================
#                              VARIABLES
# ============================================================================


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

	# Sécurité : avertit si la scène est restée en mode test
	if test_difficulty != "game":
		print("⚠️ CINEMATIC TOUCAN EN MODE TEST : ", test_difficulty)

	# Fake Moko
	moko_anim.play("idle")

	var game_state = get_node_or_null("/root/GameState")

	# Difficulté réellement utilisée par cette cinématique
	cinematic_difficulty = test_difficulty

	if cinematic_difficulty == "game":
		if game_state:
			cinematic_difficulty = game_state.difficulty
		else:
			print("❌ GameState introuvable")
			return

	print("🎬 DIFFICULTÉ CINÉMATIQUE = ", cinematic_difficulty)

	match cinematic_difficulty:

		"explorer":
			lines = [
				"Bravo, Moko !",
				"Tu as triomphé de la Jungle.",
				"Mais l’île va évoluer…",
				"Tu peux tester le Double Saut !",
				"Mode Survivant débloqué !"
			]

		"survivor":
			lines = [
				"Impressionnant, Moko !",
				"Tu as survécu à une île bien plus dangereuse.",
				"Mais elle va encore évoluer…",
				"Tu peux tester le pouvoir du Feu !",
				"Mode Roi de l’île débloqué !"
			]

		"king":
			lines = [
				"Tu l’as fait, Moko !",
				"L’île t’a tout donné.",
				"Tu as affronté sa forme ultime…",
				"Et tu es toujours debout.",
				"Tu es le Roi de l’île !"
			]

	print("📝 LINES CHARGÉES = ", lines)

	start_cinematic()

	await get_tree().create_timer(dialogue_delay).timeout
	start()


# ============================================================================
#                              CINÉMATIQUE
# ============================================================================

func start_cinematic():
	box.visible = false
	toucan.visible = true

	toucan_anim.play("intro")


# ============================================================================
#                              DIALOGUE
# ============================================================================

func start(new_lines = null):
	print("🟢 START DIALOGUE")

	if new_lines != null:
		lines = new_lines.duplicate()

	print("LINES = ", lines)

	line_index = 0
	box.visible = true

	print("BOX VISIBLE = ", box.visible)
	print("TEXT NODE = ", text)

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
	print("🎬 DIFFICULTÉ = ", cinematic_difficulty)
	print("🎞️ ANIMATIONS MOKO = ", moko_anim.get_animation_list())

	var game_state = get_node_or_null("/root/GameState")

	match cinematic_difficulty:

		# ============================================================
		# EXPLORATEUR -> DOUBLE SAUT
		# ============================================================
		"explorer":
			if moko_anim.has_animation("loot_skill"):
				print("✨ LOOT DOUBLE SAUT -> PLAY")
				moko_anim.play("loot_skill")
				await moko_anim.animation_finished
				print("✅ LOOT DOUBLE SAUT TERMINÉ")
			else:
				print("❌ Animation loot_skill introuvable")

			if game_state and test_difficulty == "game":
				game_state.unlock_next_difficulty()

		# ============================================================
		# SURVIVANT -> FIRE BUFF
		# ============================================================
		"survivor":
			if moko_anim.has_animation("fire_buff"):
				print("🔥 FIRE BUFF -> PLAY")
				moko_anim.play("fire_buff")
				await moko_anim.animation_finished
				print("✅ FIRE BUFF TERMINÉ")
			else:
				print("❌ Animation fire_buff introuvable")

			if game_state and test_difficulty == "game":
				game_state.unlock_next_difficulty()

		# ============================================================
		# ROI
		# ============================================================
		"king":
			print("🏆 VICTOIRE MODE ROI DE L'ILE")

			if game_state and test_difficulty == "game":
				if game_state.has_method("validate_current_difficulty"):
					game_state.validate_current_difficulty()

	# ================================================================
	# RETOUR MENU UNIQUEMENT EN VRAIE PARTIE
	# ================================================================
	if test_difficulty == "game":
		if game_state and game_state.has_method("load_level"):
			await game_state.load_level("res://Levels/Lvl0/lvl_0.tscn")
	else:
		print("🧪 TEST TERMINÉ — scène conservée à l'écran")
