# GameData.gd
extends Node

# 0 = Easy (Unlocked), 1 = Medium (Locked), 2 = Hard (Locked)
var difficulty_progress = {
	"Biologi": 0,
	"Fisika": 0,
	"Kimia": 0,
	"Matematika": 0
}

# Simpan resep yang sudah didapat (Array string)
var owned_recipes = []

func unlock_next_difficulty(mapel, current_diff_string):
	var current_val = 0
	if current_diff_string == "Easy": current_val = 0
	elif current_diff_string == "Medium": current_val = 1
	elif current_diff_string == "Hard": current_val = 2
	
	# Jika level yang baru diselesaikan == level yang tersimpan, unlock level berikutnya
	if current_val == difficulty_progress[mapel] and current_val < 2:
		difficulty_progress[mapel] += 1
		print("Level Up! " + mapel + " sekarang level: " + str(difficulty_progress[mapel]))

# Database Resep Lengkap
var recipe_database = {
	"Biologi": {
		"Easy": {
			"name": "Fotosintesis Sop",
			"ing": "Sayur, Air, Rempah"
		},
		"Medium": {
			"name": "Organik Opor",
			"ing": "Telur, Santan, Rempah, Air"
		},
		"Hard": {
			"name": "Dadar Nikmat Asli (DNA)",
			"ing": "Telur, Rempah, Nasi, Keju"
		}
	},
	"Fisika": {
		"Easy": {
			"name": "Steak Resistor",
			"ing": "Daging, Santan, Rempah"\
		},
		"Medium": {
			"name": "Daging Goreng Termodinamika",
			"ing": "Daging, Rempah, Air, Tepung"
		},
		"Hard": {
			"name": "Gaya Gesek Geprek",
			"ing": "Daging, Tepung, Cabe, Nasi"
		}
	},
	"Kimia": {
		"Easy": {
			"name": "Jus Elektrolit",
			"ing": "Buah, Madu, Air"
		},
		"Medium": {
			"name": "Senyawa Sambal",
			"ing": "Cabe, Sayur, Rempah"
		},
		"Hard": {
			"name": "Katalisa Kari",
			"ing": "Daging, Santan, Telur, Rempah"
		}
	},
	"Matematika": {
		"Easy": {
			"name": "π-zza",
			"ing": "Tepung, Keju, Sayur"
		},
		"Medium": {
			"name": "Sate Integral",
			"ing": "Daging, Rempah, Madu"
		},
		"Hard": {
			"name": "Nasi Pangkat Dua",
			"ing": "Nasi, Telur, Rempah"
			}
	}
}

# Fungsi untuk mengambil data resep
func get_recipe_data(mapel, difficulty):
	if recipe_database.has(mapel) and recipe_database[mapel].has(difficulty):
		return recipe_database[mapel][difficulty]
	else:
		return {"name": "???", "ing": "???", "desc": "Resep tidak ditemukan"}

func get_recipe_by_name(target_name):
	# Bersihkan nama target dari spasi hantu
	var clean_target = target_name.strip_edges()
	
	for mapel in recipe_database.keys():
		for diff in recipe_database[mapel].keys():
			var recipe_name = recipe_database[mapel][diff]["name"].strip_edges()
			if recipe_name == clean_target:
				return recipe_database[mapel][diff]
	
	print("ERROR: Resep '" + clean_target + "' tidak ditemukan di Database!")
	return null
