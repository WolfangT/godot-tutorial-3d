extends Label

var score = 0

@rpc("any_peer", "call_local")
func _update(_score, _player_id=null):
	if _player_id != null:
		GameManager.Players[_player_id].score +=1
	text = "Score: %s\n" % _score
	for id in GameManager.Players:
		if GameManager.Players[id].name == null or  GameManager.Players[id].name == "":
			text += "- %s's Score: " % id
		else:
			text += "- %s's Score: " % GameManager.Players[id].name
		text += str(GameManager.Players[id].score)
		text += "\n"

@rpc("any_peer", "call_local")
func _increment_score(_player_id) -> void:
	score += 1
	_update.rpc(score, _player_id)

func _on_mob_squashed(_player_id) -> void:
	_increment_score.rpc_id(1, _player_id)
