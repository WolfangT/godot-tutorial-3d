extends Node

@export var mob_scene: PackedScene
@export var player_scene: PackedScene

var playing = true


func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(1)
	_reset()

func _process(_delta) -> void:
	if playing:
		var local_manager = GameManager.Players[multiplayer.get_unique_id()]
		if local_manager.alive:
			$CameraPivot.position = local_manager.model.position
			$CameraPivot.position.y = 0

@rpc("any_peer", "call_local")
func _reset():
	playing = true
	$UserInterface/ScoreLabel.score = 0
	$UserInterface/ScoreLabel._update($UserInterface/ScoreLabel.score)
	$UserInterface/Retry.hide()
	var index = 1
	for _id in GameManager.Players:
		var located = false
		var current_player = player_scene.instantiate()
		current_player.get_multiplayer_authority_id = _id
		GameManager.Players[_id].model = current_player
		GameManager.Players[_id].alive = true
		current_player.jump.connect(_on_player_jump.bind(current_player))
		current_player.hit.connect(_on_player_hit.bind(_id, current_player))
		add_child(current_player, true)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(index):
				current_player.global_position = spawn.global_position
				located = true
				break
		if not located:
			current_player.global_position = $SpawnLocations / "0".global_position
		index += 1
	$MobTimer.start()

func _on_mob_timer_timeout() -> void:
	var mob = mob_scene.instantiate()
	var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
	mob_spawn_location.progress_ratio = randf()
	var player_position = get_alive_players().pick_random().position
	mob.initialize(mob_spawn_location.position, player_position)
	mob.squashed.connect($UserInterface/ScoreLabel._on_mob_squashed)
	mob.squashed.connect(_on_mob_squashed.bind(mob))
	add_child(mob)

func _on_player_hit(_id, player) -> void:
	GameManager.Players[_id].alive = false
	player.queue_free()
	$LooseSound.global_position = player.global_position
	$LooseSound.play()
	if len(get_alive_players()) == 0:
		$MobTimer.stop()
		$UserInterface/Retry.show()
		playing = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and $UserInterface/Retry.visible:
		# This restarts the current scene.
		_reset.rpc()

func _on_player_jump(player) -> void:
	$JumpSound.global_position = player.global_position
	$JumpSound.play()

func _on_mob_squashed(mob) -> void:
	$JumpSound.global_position = mob.global_position
	$ScoreSound.play()

# tools fucntions

func get_alive_players() -> Array:
	var alive_players = []
	for i in GameManager.Players:
		if GameManager.Players[i].alive:
			alive_players.append(GameManager.Players[i].model)
	return alive_players


func _on_fall_detector_body_entered(body:Node3D) -> void:
	body.die.rpc()
