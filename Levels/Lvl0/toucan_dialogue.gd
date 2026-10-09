extends Node2D

signal speech_finished

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var box = $Box
@onready var text = $Box/MarginContainer/Text


# ============================================================================
#                              RÉGLAGES
# ============================================================================

@export var chars_per_sec: float = 30.0
@export var pause_between_lines: float = 1.0
@export var intro_delay: float = 4.15


# ============================================================================
#                              VARIABLES
# ============================================================================

var lines: Array[String] = []

var line_index: int = -1
var full_line: String = ""
var shown_chars: int = 0

var writing: bool = false
var accum: float = 0.0
var pause_left: float = 0.0

var dialogue_running: bool = false


# ============================================================================
#                              INITIALISATION
# ============================================================================

func _ready():
	visible = false
	box.visible = false
	set_process(false)


# ============================================================================
#                         ARRIVÉE + SPEECH
# ============================================================================

func play_dialogue(new_lines: Array[String]):
	if dialogue_running:
		return

	if new_lines.is_empty():
		return

	dialogue_running = true
	lines = new_lines.duplicate()

	# ------------------------------------------------------------------------
	# Arrivée du Toucan
	# ------------------------------------------------------------------------

	visible = true
	box.visible = false

	if anim and anim.has_animation("intro"):
		anim.play("intro")

	await get_tree().create_timer(intro_delay).timeout

	# ------------------------------------------------------------------------
	# Début du speech
	# ------------------------------------------------------------------------

	line_index = 0
	box.visible = true
	set_process(true)

	_start_line()

	# ------------------------------------------------------------------------
	# Attend réellement la fin de toutes les phrases.
	# Le Toucan NE REPART PAS encore.
	# ------------------------------------------------------------------------

	await speech_finished


# ============================================================================
#                              DIALOGUE
# ============================================================================

func _start_line():
	if line_index >= lines.size():
		_finish_speech()
		return

	full_line = lines[line_index]

	shown_chars = 0
	accum = 0.0
	pause_left = 0.0
	writing = true

	_render()


func _process(delta):
	if not dialogue_running:
		return

	if not box.visible:
		return

	if writing:
		accum += delta

		var step := int(accum * chars_per_sec)

		if step > 0:
			accum -= float(step) / chars_per_sec
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
#                         FIN DU SPEECH
# ============================================================================

func _finish_speech():
	set_process(false)

	box.visible = false
	text.text = ""

	# IMPORTANT :
	# Le Toucan reste à l'écran.
	# Il ne joue PAS encore "fly".

	speech_finished.emit()


# ============================================================================
#                         DÉPART DU TOUCAN
# ============================================================================

func fly_away():
	# Appelé par lvl0 uniquement APRÈS
	# l'animation de récompense de Moko.

	if anim and anim.has_animation("fly"):
		anim.play("fly")
		await anim.animation_finished

	visible = false
	dialogue_running = false
