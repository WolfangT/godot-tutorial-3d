extends Label

var score = 0

func _update():
    text = "Score: %s" % score

func _on_mob_squashed() -> void:
    score += 1
    _update()