extends Label

var score = 0

@rpc("any_peer", "call_local")
func _update(_score):
    text = "Score: %s" % _score

@rpc("any_peer", "call_local")
func _increment_score() -> void:
    score += 1
    _update.rpc(score)

func _on_mob_squashed() -> void:
    _increment_score.rpc_id(1)