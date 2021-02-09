extends Node

var high_score_location := "user://high_score.sav"
func get_high_score() -> float:
	var file := File.new()
	if !file.file_exists(high_score_location):
		file.close()
		return 0.0
		
	file.open(high_score_location, File.READ)
	var score := float(file.get_line())
	file.close()
	return score

func save_high_score(score: float):
	var file := File.new()
	file.open(high_score_location, File.WRITE)
	file.store_line(str(score))
	file.close()
