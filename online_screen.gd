extends Control

# Signals

# Variables
var ip_address: String
var player_name: String
@export var port = 8910
var peer := WebSocketMultiplayerPeer.new()


func _init() -> void:
	peer.supported_protocols = ["ludus"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.server_disconnected.connect(server_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if GameManager.DedicatedServer:
		hostGame()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# main functions

func peer_connected(id: int):
	print("Player Connected: %s" % id)

func peer_disconnected(id: int):
	print("Player Disconnected: %s" % id)
	RemovePlayerInformation.rpc(id)
	
func connected_to_server():
	print("Connected to Server")
	SendPlayerInformation.rpc_id(1, multiplayer.get_unique_id(), $NameLine.text)

func connection_failed():
	print("Connection Failed")

func server_disconnected():
	print("Server Disconected")
	get_tree().root.get_node("MainGame").playing = false
	get_tree().root.get_node("MainGame").queue_free()
	get_tree().change_scene_to_file("res://main.tscn")

@rpc("any_peer", "call_remote")
func SendPlayerInformation(id: int, _name: String):
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
			SendPlayerInformation.rpc(i, GameManager.Players[i].name)
	update_player_list()

@rpc("any_peer", "call_local")
func RemovePlayerInformation(id: int):
	if GameManager.Players.has(id):
		if GameManager.Players[id].model != null:
			GameManager.Players[id].model.queue_free()
		GameManager.Players.erase(id)
	update_player_list()
	

@rpc("any_peer", "call_local")
func StartGame():
	var scene = load("res://main_game.tscn").instantiate()
	get_tree().root.add_child(scene)
	hide()

func create_tls_options() -> TLSOptions:
	var server_certs = X509Certificate.new()
	server_certs.load("/etc/letsencrypt/live/www.wolfang.info.ve/cert.pem")
	var server_key = CryptoKey.new()
	server_key.load("/etc/letsencrypt/live/www.wolfang.info.ve/privkey.pem")
	var server_tls_options = TLSOptions.server(server_key, server_certs)
	return server_tls_options

func hostGame():
	var error = peer.create_server(port, "0.0.0.0", create_tls_options())
	if error != OK:
		print("Cannot host: %s" % error)
		return
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for Players!")

func update_player_list():
	var players_text = "Players List\n========\n"
	for id in GameManager.Players:
		if GameManager.Players[id].name == null or  GameManager.Players[id].name == "":
			players_text += "- %s" % id
		else:
			players_text += "- %s" % GameManager.Players[id].name
		if id == 1:
			players_text += " (host)"
		players_text += "\n"
	$PlayersList.text = players_text

# callbacks

func _on_host_button_pressed() -> void:
	hostGame()
	SendPlayerInformation(multiplayer.get_unique_id(), $NameLine.text)

func _on_connect_button_pressed() -> void:
	ip_address = $IPLine.text
	print("ip_address %s" % ip_address) 
	peer.create_client("wss://" + ip_address + ":" + str(port), TLSOptions.client_unsafe())
	multiplayer.set_multiplayer_peer(peer)

func _on_start_button_pressed() -> void:
	StartGame.rpc()
