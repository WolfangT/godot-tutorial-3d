extends Control

# Signals

# Variables
@export var PROTOCOL := "wss"
@export var HOST_NAME := "www.wolfang.info.ve"
@export var PORT := 9080
@export var MESH := true

var SIGNALING_SERVER := "%s://%s:%s" % [PROTOCOL, HOST_NAME, PORT]

var player_name: String

# Called on node creation
func _init() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	if GameManager.DedicatedServer:
		pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# Networtk callbacks

func _on_peer_connected(id: int) -> void:
	print("[Multiplayer] Player Connected: %s" % id)

func _on_peer_disconnected(id: int) -> void:
	print("[Multiplayer] Player Disconnected: %s" % id)
	remove_player_information.rpc(id)
	
func _on_connected_to_server() -> void:
	print("[Multiplayer] Connected to Server")
	send_player_information.rpc_id(1, multiplayer.get_unique_id(), $NameLine.text)

func _on_connection_failed() -> void:
	print("[Multiplayer] Connection Failed")

func _on_server_disconnected() -> void:
	print("[Multiplayer] Server Disconected")
	# get_tree().root.get_node("MainGame").playing = false
	get_tree().root.get_node("MainGame").queue_free()
	get_tree().change_scene_to_file("res://main.tscn")

func _on_client_connected(id: int, use_mesh: bool) -> void:
	print("[Signaling] Server connected with ID: %d. Mesh: %s" % [id, use_mesh])

func _on_client_disconnected() -> void:
	print("[Signaling] Server disconnected: %d - %s" % [$Client.code, $Client.reason])

func _on_client_lobby_joined(lobby: String) -> void:
	$LobbyLine.text = lobby
	$LobbyLine.editable = false
	$StartButton.disabled = false
	$NameLine.editable = false
	if multiplayer.is_server():
		send_player_information(1, $NameLine.text)
	print("[Signaling] Joined lobby %s" % lobby)

func _on_client_lobby_sealed() -> void:
	print("[Signaling] Lobby has been sealed")

func _on_client_finished_connection() -> void:
	print("[Multiplayer] Sending Personal Info to the Server")
	send_player_information.rpc_id(1, multiplayer.get_unique_id(), $NameLine.text)


# callbacks

func _on_host_button_pressed() -> void:
	$Client.start(SIGNALING_SERVER, "", MESH)

func _on_connect_button_pressed() -> void:
	$Client.start(SIGNALING_SERVER, $LobbyLine.text, MESH)

func _on_start_button_pressed() -> void:
	start_game.rpc()


# Server comunications

@rpc("any_peer", "call_remote", "reliable")
func send_player_information(id: int, _name: String) -> void:
	print("Received id %s and name %s" % [id, _name])
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": _name,
			"id": id,
			"score": 0,
			"model": null,
			"alive": false,
		}
	if multiplayer.is_server():
		for i in GameManager.Players:
			send_player_information.rpc(i, GameManager.Players[i].name)
	update_player_list()

@rpc("any_peer", "call_local", "reliable")
func remove_player_information(id: int):
	if GameManager.Players.has(id):
		if GameManager.Players[id].model != null:
			GameManager.Players[id].model.queue_free()
		GameManager.Players.erase(id)
	update_player_list()
	

@rpc("any_peer", "call_local", "reliable")
func start_game() -> void:
	var scene = load("res://src/main_game.tscn").instantiate()
	get_tree().root.add_child(scene)
	hide()

# Main Fuctions

func update_player_list():
	var players_text = "Players List:\n"
	for id in GameManager.Players:
		if GameManager.Players[id].name == null or GameManager.Players[id].name == "":
			players_text += "- %s" % id
		else:
			players_text += "- %s" % GameManager.Players[id].name
		if id == 1:
			players_text += " (host)"
		players_text += "\n"
	$PlayersList.text = players_text
