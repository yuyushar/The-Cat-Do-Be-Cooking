extends Area2D
# Script ini hanya sebagai penanda area visual
var current_ingredients = []

func _ready():
	connect("area_entered", self, "_on_ingredient_entered")

func _on_ingredient_entered(area):
	if area.is_in_group("Ingredient") and not area.get_parent().is_dragging:
		area.get_parent().snap_to_pot(self)

func add_ingredient_data(nama_bahan):
	current_ingredients.append(nama_bahan)
	print("Bahan Masuk: ", nama_bahan)
	print("Isi Panci Sekarang: ", current_ingredients)
