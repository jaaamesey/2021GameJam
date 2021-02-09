extends Node

func get_high_score() -> float:
	var file := File.new()
	file.open("user://high_score.sav", File.READ)
	var score := float(file.get_line())
	file.close()
	return score

func save_high_score(score: float):
	var file := File.new()
	file.open("user://high_score.sav", File.WRITE)
	file.store_line(str(score))
	file.close()
