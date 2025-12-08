extends Node

var soal_data = {}

func load_json():
	var file = File.new()
	if file.file_exists("res://data/soal.json") == false:
		print("❗ soal.json tidak ditemukan!")
		return

	file.open("res://data/soal.json", File.READ)
	soal_data = parse_json(file.get_as_text())
	file.close()
	print("✔ JSON Loaded, total mapel:", soal_data.keys().size())


func get_questions(subject:String, difficulty:String) -> Array:
	var result = []

	if not soal_data.has(subject):
		print("Mapel tidak ditemukan:", subject)
		return result

	for nomor in soal_data[subject].keys():
		var id = int(nomor)

		match difficulty:
			"Easy":
				if id <= 3: result.append(soal_data[subject][nomor])
			"Medium":
				if id >= 4 and id <= 8: result.append(soal_data[subject][nomor])
			"Hard":
				if id >= 9: result.append(soal_data[subject][nomor])

	result.shuffle()
	return result
