extends Control

# Memuat template bahan
onready var ingredient_scene = preload("res://Scene/IngredientObject.tscn")
onready var hover_label = $HoverLabel
var bahan_di_panci = []
var resep_target_nama = ""
var bahan_target_list = []
var customer_count = 0
var max_customers = 5
var is_busy = false
var current_npc = null
var npc_default_pos = Vector2.ZERO
onready var order_ui = $Order/Control
onready var order_label = $Order/Control/Label
onready var recipe_book_ui = $Recipe
onready var day_popup = $DayFinishedPopup
onready var dark_overlay = $DarkOverlay
var current_page_index = 0
onready var pages = [
	$Recipe/Pages/Page_Biologi,
	$Recipe/Pages/Page_Fisika,
	$Recipe/Pages/Page_Kimia,
	$Recipe/Pages/Page_Matematika
]
onready var food_result_display = $FoodResultDisplay 

func _ready():
	FX.play_fast()
	if hover_label: hover_label.hide()
	var daftar_nama = ["Air", "Buah", "Cabe", "Daging", "Telur", "Keju", "Madu", "Nasi", "Rempah", "Santan", "Sayur", "Tepung"]
	
	for nama in daftar_nama:
		var btn = TextureButton.new()
		var path = "res://asset/ingridients/" + nama.to_lower() + ".png"
		btn.texture_normal = load(path)
		btn.expand = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED 
		btn.rect_min_size = Vector2(158, 158)
		
		btn.connect("button_down", self, "_on_rak_diklik", [nama, path])
		_add_hover(btn, nama, "bawah")
		$IngredientsGrid.add_child(btn) 
		
	var btn_continue = day_popup.get_node("VBoxContainer/ContinueButton")
	var btn_map = day_popup.get_node("VBoxContainer/MapButton")
	$Recipe/NextPage.connect("pressed", self, "_on_NextPage_pressed")
	$BtnBukaResep.connect("pressed", self, "_on_BtnBukaResep_pressed")
	$Recipe/PrevPage.connect("pressed", self, "_on_PrevPage_pressed")
	btn_continue.connect("pressed", self, "_on_ContinueButton_pressed")
	btn_map.connect("pressed", self, "_on_MapButton_pressed")
	_add_hover($Spoon, "Aduk Masakan", "atas")
	_add_hover($BtnBukaResep, "Buku Resep", "atas")
	_add_hover($Recipe/NextPage, "Halaman Selanjutnya", "bawah")
	_add_hover($Recipe/PrevPage, "Halaman Sebelumnya", "bawah")
	_add_hover(btn_continue, "Lanjut Hari Berikutnya", "atas")
	_add_hover(btn_map, "Kembali ke Peta Utama", "atas")
	npc_default_pos = order_ui.get_node("Npc1").position
	day_popup.hide()
	dark_overlay.hide()
	food_result_display.hide()
	recipe_book_ui.hide()
	buka_halaman(0)
	update_recipe_book_visuals()
	mulai_pesanan_baru()
func mulai_pesanan_baru():
	for i in range(1, 7):
		order_ui.get_node("Npc" + str(i)).hide()
	$Order/Control/OrderBubble.hide()
	if customer_count >= max_customers:
		tampilkan_popup_hari_selesai()
		return
	var random_index = randi() % 6 + 1
	var next_npc = order_ui.get_node("Npc" + str(random_index))
	current_npc = next_npc
	customer_count += 1
	next_npc.position = Vector2(npc_default_pos.x - 400, npc_default_pos.y)
	next_npc.modulate.a = 0.0
	next_npc.show()
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(next_npc, "position", npc_default_pos, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(next_npc, "modulate:a", 1.0, 0.4)
	if GameData.owned_recipes.size() > 0:
		resep_target_nama = GameData.owned_recipes[randi() % GameData.owned_recipes.size()]
		
		var data_resep = GameData.get_recipe_by_name(resep_target_nama)
		
		if data_resep == null:
			print("CRASH AVOIDED: Data resep null untuk: ", resep_target_nama)
			return
		
		var raw_list = data_resep["ing"].split(",")
		bahan_target_list = []
		for item in raw_list:
			bahan_target_list.append(item.strip_edges())
		yield(get_tree().create_timer(0.5), "timeout")
		var bubble = $Order/Control/OrderBubble
		bubble.get_node("FoodLabel").text = resep_target_nama
		bubble.rect_pivot_offset = bubble.rect_size / 2
		var icon_path = "res://asset/food/" + resep_target_nama.to_lower().replace(" ", "_") + ".png"
		if File.new().file_exists(icon_path):
			bubble.get_node("FoodIcon").texture = load(icon_path)
		
		bubble.show()
		bubble.rect_scale = Vector2(0,0)
		create_tween().tween_property(bubble, "rect_scale", Vector2(1,1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		print("DEBUG: Pelanggan minta: ", resep_target_nama)
	else:
		print("DEBUG: Player belum punya resep apapun!")
func _on_rak_diklik(nama, path):
	var new_item = ingredient_scene.instance()
	add_child(new_item)
	new_item.global_position = get_global_mouse_position()
	new_item.setup_bahan(nama, path)

func tambah_bahan_ke_list(nama, pos_jatuh):
	if pos_jatuh.y > 600:
		bahan_di_panci.append(nama)
		print("Isi Panci: ", bahan_di_panci)
	else:
		print("Bahan terbuang ke samping!") 
func _add_hover(btn_node, text, posisi="atas"):
	if not btn_node.is_connected("mouse_entered", self, "_on_btn_hover"):
		btn_node.connect("mouse_entered", self, "_on_btn_hover", [btn_node, text, posisi])
		btn_node.connect("mouse_exited", self, "_on_btn_exit")
func _on_Spoon_pressed():
	if bahan_di_panci.size() == 0:
		print("Panci kosong, tidak bisa mengaduk!")
		return
	
	$Spoon.disabled = true
	
	$TitleChar.play("start")
	yield($TitleChar, "animation_finished")
	
	for i in range(2):
		$TitleChar.play("loop")
		yield($TitleChar, "animation_finished")
		print("Sedang mengaduk... Loop ke-", i+1)
	
	$TitleChar.play("finish")
	yield($TitleChar, "animation_finished")
	
	if $TitleChar.frames.has_animation("idle"):
		$TitleChar.play("idle")
	
	cek_hasil_masakan()
	
	$Spoon.disabled = false
	
func cek_hasil_masakan():
	var panci_sort = Array(bahan_di_panci) 
	panci_sort.sort()
	
	var target_sort = Array(bahan_target_list)
	target_sort.sort()
	
	print("Mencocokkan: ", panci_sort, " dengan ", target_sort)

	if panci_sort == target_sort:
		print("MASAKAN BERHASIL!")
		var clean_name = resep_target_nama.to_lower().replace(" ", "_")
		var path = "res://asset/food/" + clean_name + ".png"
		
		yield(tampilkan_animasi_hasil(path, false), "completed")
		
		bahan_di_panci.clear()
		pindah_ke_customer_selanjutnya()
		
	else:
		print("MASAKAN SALAH!")
		var masakan_terbuat = cari_masakan_dari_isi_panci()
		if masakan_terbuat != null and masakan_terbuat in GameData.owned_recipes:
			print("Salah order! Player malah bikin: ", masakan_terbuat)
			
			var clean_name = masakan_terbuat.to_lower().replace(" ", "_")
			var path = "res://asset/food/" + clean_name + ".png"
			
			yield(tampilkan_animasi_hasil(path, true), "completed")
			
		else:
			print("Jadi sampah (Kombinasi ngawur atau resep belum di-unlock)")
			var path_trash = "res://asset/food/trash.png" 
			yield(tampilkan_animasi_hasil(path_trash, false), "completed")
		bahan_di_panci.clear()

func pindah_ke_customer_selanjutnya():
	bahan_di_panci.clear()
	var bubble = $Order/Control/OrderBubble
	create_tween().tween_property(bubble, "rect_scale", Vector2(0,0), 0.2)
	if current_npc != null:
		var tw_exit = create_tween()
		tw_exit.set_parallel(true)
		var target_y = npc_default_pos.y + 600
		tw_exit.tween_property(current_npc, "position:y", target_y, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw_exit.tween_property(current_npc, "modulate:a", 0.0, 0.5)
		yield(tw_exit, "finished")
		
		current_npc.hide()
		current_npc = null
	if customer_count >= max_customers:
		tampilkan_popup_hari_selesai()
	else:
		mulai_pesanan_baru()

func tampilkan_popup_hari_selesai():
	day_popup.show()
	day_popup.rect_scale = Vector2(0, 0)
	day_popup.rect_pivot_offset = day_popup.rect_size / 2
	var tween = create_tween()
	tween.tween_property(day_popup, "rect_scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	print("Hari selesai! Muncul pop-up.")
	
func _on_ContinueButton_pressed():
	customer_count = 0
	day_popup.hide()
	for i in range(1, 7):
		var npc = order_ui.get_node("Npc" + str(i))
		npc.hide()
		npc.position = npc_default_pos 
		npc.modulate.a = 1.0
	mulai_pesanan_baru()
	print("Memulai hari baru di Kitchen.")

func _on_MapButton_pressed():
	FX.play_slow()
	get_tree().change_scene("res://Scene/Map.tscn")
func _on_NextPage_pressed():
	if is_busy or current_page_index >= pages.size() - 1: return
	
	is_busy = true
	$Recipe/Pages.hide()
	
	$Recipe/Book_animated.speed_scale = 1.0
	$Recipe/Book_animated.frame = 0
	$Recipe/Book_animated.play("next")
	
	yield(get_tree().create_timer(0.4), "timeout")
	
	current_page_index += 1
	buka_halaman(current_page_index)
	$Recipe/Pages.show()
	is_busy = false

func _on_PrevPage_pressed():
	if is_busy or current_page_index <= 0: 
		return
	
	is_busy = true
	$Recipe/Pages.hide()
	
	$Recipe/Book_animated.speed_scale = 1.0
	$Recipe/Book_animated.frame = 0
	$Recipe/Book_animated.play("prev")
	
	yield(get_tree().create_timer(0.4), "timeout")
	
	current_page_index -= 1
	buka_halaman(current_page_index)
	$Recipe/Pages.show()
	
	is_busy = false
func buka_halaman(index):
	current_page_index = index
	
	for i in range(pages.size()):
		if pages[i] != null:
			pages[i].visible = (i == index)
	var btn_prev = get_node_or_null("Recipe/PrevPage") 
	var btn_next = get_node_or_null("Recipe/NextPage")
	if btn_prev == null: btn_prev = get_node_or_null("PrevPage")
	if btn_next == null: btn_next = get_node_or_null("NextPage")
	if btn_prev:
		btn_prev.visible = (index > 0)
	if btn_next:
		btn_next.visible = (index < pages.size() - 1)
func update_recipe_book_visuals():
	var db = GameData.recipe_database
	
	for mapel in db.keys():
		for diff in db[mapel].keys():
			var data = db[mapel][diff]
			var nama_resep = data["name"]
			var slot_path = "Recipe/Pages/Page_" + mapel + "/Slot_" + diff
			
			if has_node(slot_path):
				var slot = get_node(slot_path)
				
				if nama_resep in GameData.owned_recipes:
					slot.modulate = Color(1, 1, 1)
					slot.get_node("FoodName").text = nama_resep
					
					var food_path = "res://asset/food/" + nama_resep.to_lower().replace(" ", "_") + ".png"
					if File.new().file_exists(food_path):
						slot.get_node("FoodIcon").texture = load(food_path)
					slot.get_node("IngLabel").text = data["ing"].replace(",", " +")
					var container = slot.get_node("IngContainer")
					for child in container.get_children():
						child.queue_free()
					var list_bahan = data["ing"].split(",")
					for bahan in list_bahan:
						var nama_bersih = bahan.strip_edges()
						var icon_rect = TextureRect.new()
						var icon_path = "res://asset/ingridients/" + nama_bersih.to_lower() + ".png"
						
						if File.new().file_exists(icon_path):
							icon_rect.texture = load(icon_path)
							icon_rect.expand = true
							icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
							icon_rect.rect_min_size = Vector2(40, 40) # Ukuran ikon kecil
							container.add_child(icon_rect)
				
				else:
					slot.modulate = Color(0.2, 0.2, 0.2) # Gelap
					slot.get_node("FoodName").text = "???"
					slot.get_node("IngLabel").text = "Terkunci"
					slot.get_node("FoodIcon").texture = null
					for child in slot.get_node("IngContainer").get_children():
						child.queue_free()
func _on_BtnBukaResep_pressed():
	if is_busy: return
	
	is_busy = true
	
	if recipe_book_ui.visible:
		var tween = create_tween()
		tween.tween_property(dark_overlay, "modulate:a", 0.0, 0.3)
		yield(tween, "finished")
		dark_overlay.hide()
		$Recipe/Pages.hide()
		$Recipe/NextPage.hide()
		$Recipe/PrevPage.hide()
		
		$Recipe/Book_animated.play("close")
		yield(get_tree().create_timer(0.7), "timeout")
		
		recipe_book_ui.hide()
	else:
		dark_overlay.show()
		dark_overlay.modulate.a = 0
		var tween=create_tween()
		tween.tween_property(dark_overlay, "modulate:a", 0.55, 0.3)
		update_recipe_book_visuals()
		
		$Recipe/Pages.hide()
		$Recipe/NextPage.hide()
		$Recipe/PrevPage.hide()
		
		recipe_book_ui.show()
		$Recipe/Book_animated.play("open")
		
		yield(get_tree().create_timer(0.5), "timeout")
		
		$Recipe/Pages.show()
		buka_halaman(current_page_index)
	is_busy = false

func cari_masakan_dari_isi_panci():
	var bahan_sekarang = Array(bahan_di_panci)
	bahan_sekarang.sort()	
	var db = GameData.recipe_database
	for mapel in db.keys():
		for diff in db[mapel].keys():
			var data = db[mapel][diff]
			var bahan_resep = data["ing"].split(",")
			var target_sort = []
			for b in bahan_resep:
				target_sort.append(b.strip_edges())
			target_sort.sort()
			if bahan_sekarang == target_sort:
				return data["name"]
	return null
func tampilkan_animasi_hasil(texture_path, is_darkened):
	if File.new().file_exists(texture_path):
		food_result_display.texture = load(texture_path)
	else:
		print("Gambar tidak ditemukan: ", texture_path)
		return
	if is_darkened:
		food_result_display.modulate = Color(0.4, 0.4, 0.4, 1)
	else:
		food_result_display.modulate = Color(1, 1, 1, 1)

	food_result_display.show()
	food_result_display.rect_pivot_offset = food_result_display.rect_size / 2
	food_result_display.rect_scale = Vector2(0, 0)
	
	var tween = create_tween()
	tween.tween_property(food_result_display, "rect_scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(food_result_display, "rect_scale", Vector2(1.0, 1.0), 0.1)
	
	yield(get_tree().create_timer(2.0), "timeout")

	var close_tween = create_tween()
	close_tween.tween_property(food_result_display, "rect_scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	yield(close_tween, "finished")
	
	food_result_display.hide()
	food_result_display.modulate = Color(1, 1, 1, 1)

func _on_btn_hover(btn_node, text, posisi = "atas"):
	if posisi == "bawah" and (recipe_book_ui.visible or day_popup.visible):
		return

	hover_label.text = text
	hover_label.rect_size = Vector2(0, 0)
	hover_label.show()
	yield(get_tree(), "idle_frame") 
	
	if is_instance_valid(btn_node):
		var global_pos = btn_node.rect_global_position
		var total_scale = btn_node.get_global_transform().get_scale()
		var true_width = btn_node.rect_size.x * total_scale.x
		var true_height = btn_node.rect_size.y * total_scale.y
		
		var label_size = hover_label.rect_size
		var pos_x = global_pos.x + (true_width / 2) - (label_size.x / 2)
		var pos_y = 0
		if posisi == "bawah":
			pos_y = global_pos.y + true_height + 5 
		else:
			pos_y = global_pos.y - label_size.y - 10
		
		hover_label.rect_global_position = Vector2(pos_x, pos_y)
		hover_label.raise()

func _on_btn_exit():
	hover_label.hide()
func _on_ingredient_exit():
	hover_label.hide()
