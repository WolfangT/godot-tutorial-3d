extends Node

# Variables
@export var mob_scene: PackedScene
@export var player_scene: PackedScene

var playing = true

# Node process

func _init() -> void:
	pass

func _ready() -> void:
	$MultiplayerSynchronizer.set_multiplayer_authority(1)
	$MultiplayerSpawner.set_multiplayer_authority(1)
	$MultiplayerSpawner.set_spawn_function(_spawn_creep)
	_reset.rpc()
	if multiplayer.is_server():
		$MobTimer.start()

func _process(_delta) -> void:
	if playing and GameManager.Players.has(multiplayer.get_unique_id()):
		var local_manager = GameManager.Players[multiplayer.get_unique_id()]
		if local_manager.alive:
			$CameraPivot.position = local_manager.model.position
			$CameraPivot.position.y = 0
	if multiplayer.is_server():
		$MobTimer.wait_time = get_spawn_time()

func _unhandled_input(event) -> void:
	if event.is_action_pressed("ui_accept") and $UserInterface/Retry.visible:
		# This restarts the current scene.
		_reset.rpc()

# Main functions

@rpc("any_peer", "call_local")
func _reset():
	playing = true
	$UserInterface/ScoreLabel.score = 0
	$UserInterface/ScoreLabel._update($UserInterface/ScoreLabel.score)
	$UserInterface/Retry.hide()
	var index = 1
	for _id in GameManager.Players:
		var current_player = player_scene.instantiate()
		current_player.get_multiplayer_authority_id = _id
		if GameManager.Players[_id].model != null:
			GameManager.Players[_id].model.queue_free()
		GameManager.Players[_id].model = current_player
		GameManager.Players[_id].alive = true
		current_player.jump.connect(_on_player_jump.bind(current_player))
		current_player.hit.connect(_on_player_hit.bind(_id, current_player))
		current_player.squashed.connect($UserInterface/ScoreLabel._on_player_squashed)
		current_player.squashed.connect(_on_player_squashed)
		add_child(current_player, true)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(index):
				current_player.global_position = spawn.global_position
				break
		index += 1
	$MobTimer.start()

func _spawn_creep(data) -> Node:
	var mob = mob_scene.instantiate()
	var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
	mob_spawn_location.progress_ratio = data[0]
	mob.initialize(mob_spawn_location.position, data[1], get_mob_speed_mult())
	mob.squashed.connect($UserInterface/ScoreLabel._on_mob_squashed)
	mob.squashed.connect(_on_mob_squashed.bind(mob))
	return mob

# Callbacks

func _on_mob_timer_timeout() -> void:
	var progress_ratio: float = randf()
	var players := get_alive_players()
	var player_position: Vector3
	if len(players) == 0:
		player_position = Vector3.ZERO
	else:
		player_position = players.pick_random().global_position
	$MultiplayerSpawner.spawn([progress_ratio, player_position])

func _on_player_hit(_id, player) -> void:
	GameManager.Players[_id].alive = false
	player.queue_free()
	$LooseSound.global_position = player.global_position
	$LooseSound.play()

func _on_player_jump(player) -> void:
	$JumpSound.global_position = player.global_position
	$JumpSound.play()

func _on_mob_squashed(_player_id, mob) -> void:
	$JumpSound.global_position = mob.global_position
	$ScoreSound.play()

func _on_player_squashed(_jumper_id: int, squashed_id: int) -> void:
	$JumpSound.global_position = GameManager.Players[squashed_id].model.global_position
	$ScoreSound.play()

func _on_fall_detector_body_entered(body: Node3D) -> void:
	body.die.rpc()

func _on_despawn_detector_body_exited(body: Node3D) -> void:
	if body.is_in_group("mob"):
		body.die.rpc()


# Tools fucntions

func get_alive_players() -> Array:
	var alive_players = []
	for i in GameManager.Players:
		if GameManager.Players[i].alive:
			alive_players.append(GameManager.Players[i].model)
	if len(alive_players) == 0:
		$MobTimer.stop()
		$UserInterface/Retry.show()
		playing = false
	return alive_players

func get_spawn_time() -> float:
	var top_score = 100
	var top_time = 0.1
	var bottom_time = 1
	var spawn_time = bottom_time - \
			$UserInterface/ScoreLabel.score * ((top_time - bottom_time) / top_score)
	return spawn_time


func get_mob_speed_mult() -> float:
	var top_score = 100
	var top_mult = 5
	var bottom_mult = 0.5
	var speed_mult = bottom_mult + \
			$UserInterface/ScoreLabel.score * ((top_mult - bottom_mult) / top_score)
	return speed_mult
