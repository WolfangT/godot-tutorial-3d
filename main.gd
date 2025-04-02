extends Node

@export var mob_scene: PackedScene
var playing = true


func _process(_delta) -> void:
    if playing:
        $CameraPivot.position = $Player.position

func _on_mob_timer_timeout() -> void:
    var mob = mob_scene.instantiate()
    var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
    mob_spawn_location.progress_ratio = randf()
    var player_position = $Player.position
    mob.initialize(mob_spawn_location.position, player_position)
    mob.squashed.connect($UserInterface/ScoreLabel._on_mob_squashed.bind())
    mob.squashed.connect(_on_mob_squashed.bind())
    add_child(mob)

func _on_player_hit() -> void:
    $LooseSound.play()
    $MobTimer.stop()
    $UserInterface/Retry.show()
    playing = false

func _ready():
    $UserInterface/Retry.hide()

func _unhandled_input(event):
    if event.is_action_pressed("ui_accept") and $UserInterface/Retry.visible:
        # This restarts the current scene.
        get_tree().reload_current_scene()

func _on_player_jump() -> void:
    $JumpSound.position = $Player.position
    $JumpSound.play()

func _on_mob_squashed() -> void:
    $ScoreSound.play()