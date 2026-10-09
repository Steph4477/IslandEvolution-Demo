extends Node2D

@onready var toucan_dialogue = $ToucanDialogue
@onready var environment_sprite = $Background/AnimatedSprite2D
@onready var smoke_ceiling = $Background/SmokeCeilling
@onready var fire_fx = $Background/FireFx

var gs
var player = null


func _ready():
	$sound/dijee.play()

	gs = get_node("/root/GameState")

	gs.load_global_progress()

	refresh_difficulty_buttons()
	_apply_environment_difficulty()


# ============================================================================
#                         ENVIRONNEMENT DU MENU
# ============================================================================
# ============================================================================
#                         ENVIRONNEMENT DU MENU
# ============================================================================
func _apply_environment_difficulty():
	environment_sprite.visible = true

	# Reset FX
	smoke_ceiling.visible = false
	fire_fx.visible = false

	# KING
	if gs.survivor_unlocked or gs.king_unlocked:
		environment_sprite.play("environment_king")
		smoke_ceiling.visible = true
		fire_fx.visible = true

	# SURVIVOR
	elif gs.explorer_unlocked:
		environment_sprite.play("environment_survivor")
		smoke_ceiling.visible = true
		fire_fx.visible = false

	# EXPLORER
	else:
		environment_sprite.play("environment_explorer")


# ============================================================================
#                         AFFICHAGE DIFFICULTÉS
# ============================================================================

func refresh_difficulty_buttons():
	# ------------------------------------------------------------------------
	# EXPLORATEUR
	# ------------------------------------------------------------------------
	$DifficultyButtons/Unlocked/Explorer.visible = gs.explorer_unlocked
	$DifficultyButtons/Locked/Explorer.visible = not gs.explorer_unlocked

	# ------------------------------------------------------------------------
	# SURVIVANT
	# ------------------------------------------------------------------------
	$DifficultyButtons/Unlocked/Survivor.visible = gs.survivor_unlocked
	$DifficultyButtons/Locked/Survivor.visible = not gs.survivor_unlocked

	# ------------------------------------------------------------------------
	# ROI DE L'ÎLE
	# ------------------------------------------------------------------------
	$DifficultyButtons/Unlocked/King.visible = gs.king_unlocked
	$DifficultyButtons/Locked/King.visible = not gs.king_unlocked


# ============================================================================
#                              OPTIONS
# ============================================================================

func _on_options_pressed():
	await gs.load_level("res://Interface/Configuration/configuration.tscn")


# ============================================================================
#                           NOUVELLE PARTIE
# ============================================================================

func _on_restart_pressed():
	await gs.restart_game()


# ============================================================================
#                               CHARGER
# ============================================================================

func _on_load_pressed():
	await gs.load_save()


# ============================================================================
#                              SAUVEGARDER
# ============================================================================

func _on_save_pressed():
	gs.save_game()


# ============================================================================
#                               CONTINUER
# ============================================================================

func _on_continue_pressed():
	await gs.continue_game()


# ============================================================================
#                                QUITTER
# ============================================================================

func _on_quitter_pressed():
	get_tree().quit()
