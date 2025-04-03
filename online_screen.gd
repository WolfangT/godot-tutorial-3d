extends Control

# Signals

# Variables
var ip_address : String
var player_name : String
@export var port = 8910
var peer:ENetMultiplayerPeer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# main functions

func peer_connected(id:int):
	print("Player Connected: %s" % id)

func peer_disconnected(id:int):
	print("Player Disconnected: %s" % id)
	
func connected_to_server():
	print("Connected to Server")
	SendPlayerInformation.rpc_id(1, multiplayer.get_unique_id(), $NameLine.text)

func connection_failed():
	print("Connection Failed")

@rpc("any_peer", "call_remote")
func SendPlayerInformation(id:int, _name:String):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name" : _name,
			"id" : id,
			"score" : 0,
		}
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(i,  GameManager.Players[i].name)

@rpc("any_peer", "call_local")
func StartGame():
	var scene = load("res://main_game.tscn").instantiate()
	get_tree().root.add_child(scene)
	hide()

# callbacks

func _on_host_button_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port)
	if error != OK:
		print("Cannot host: %s" % error)
		return
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for Players!")
	SendPlayerInformation(multiplayer.get_unique_id(), $NameLine.text)

func _on_connect_button_pressed() -> void:
	ip_address = $IPLine.text
	print("ip_address %s" % ip_address) 
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address, port)
	multiplayer.set_multiplayer_peer(peer)

func _on_start_button_pressed() -> void:
	StartGame.rpc()
