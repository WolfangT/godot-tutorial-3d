extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		GameManager.DedicatedServer = true
		RenderingServer.render_loop_enabled = false
	else:
		get_tree().root.get_node("MusicPlayer").play()
	get_tree().root.add_child.call_deferred(load("res://src/online_screen.tscn").instantiate())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
