extends Node

@export var mob_scene: PackedScene
@export var player_scene: PackedScene

var playing = true
var players = []


func _ready():
	_reset()

func _process(_delta) -> void:
	pass
	# if playing:
	#     $CameraPivot.position = $Player.position

func _reset():
	players = []
	$UserInterface/ScoreLabel.score = 0
	$UserInterface/ScoreLabel._update()
	$UserInterface/Retry.hide()
	var index = 1
	for i in GameManager.Players:
		var located = false
		var current_player = player_scene.instantiate()
		players.append(current_player)
		current_player.jump.connect(_on_player_jump.bind(current_player))
		current_player.hit.connect(_on_player_hit.bind(current_player))
		add_child(current_player)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(index):
				current_player.global_position = spawn.global_position
				located = true
				break
		if not located:
			current_player.global_position = $SpawnLocations/"0".global_position
		index += 1
	$MobTimer.start()

func _on_mob_timer_timeout() -> void:
	var mob = mob_scene.instantiate()
	var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
	mob_spawn_location.progress_ratio = randf()
	var player_position = players.pick_random().position
	mob.initialize(mob_spawn_location.position, player_position)
	mob.squashed.connect($UserInterface/ScoreLabel._on_mob_squashed)
	mob.squashed.connect(_on_mob_squashed.bind(mob))
	add_child(mob)

func _on_player_hit(player) -> void:
	$LooseSound.global_position = player.global_position
	$LooseSound.play()
	$MobTimer.stop()
	$UserInterface/Retry.show()
	playing = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and $UserInterface/Retry.visible:
		# This restarts the current scene.
		_reset()

func _on_player_jump(player) -> void:
	$JumpSound.global_position = player.global_position
	$JumpSound.play()

func _on_mob_squashed(mob) -> void:
	$JumpSound.global_position = mob.global_position
	$ScoreSound.play()
