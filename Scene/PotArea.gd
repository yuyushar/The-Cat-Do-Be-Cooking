extends Area2D

# Array untuk menyimpan bahan yang sudah masuk
var current_ingredients = []

func _ready():
	# Hubungkan signal saat ada area lain masuk
	connect("area_entered", self, "_on_ingredient_entered")

func _on_ingredient_entered(area):
	# Cek apakah yang masuk itu adalah grup "Ingredient"
	if area.is_in_group("Ingredient") and not area.get_parent().is_dragging:
		# Panggil fungsi masak di script Ingredient
		area.get_parent().snap_to_pot(self)

func add_ingredient_data(nama_bahan):
	current_ingredients.append(nama_bahan)
	print("Bahan Masuk: ", nama_bahan)
	print("Isi Panci Sekarang: ", current_ingredients)
	
	# --- CEK RESEP DISINI NANTI ---
	# check_recipe_status()
