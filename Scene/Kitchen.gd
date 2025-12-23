extends Control

# Memuat template bahan
onready var ingredient_scene = preload("res://Scene/IngredientObject.tscn")
var bahan_di_panci = []
var resep_target_nama = ""
var bahan_target_list = []
var customer_count = 0
var max_customers = 5
var is_busy = false
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
	# Daftar 12 bahan sesuai urutan rak kayu kamu
	var daftar_nama = ["Air", "Buah", "Cabe", "Daging", "Telur", "Keju", "Madu", "Nasi", "Rempah", "Santan", "Sayur", "Tepung"]
	
	# Generate 12 tombol di GridContainer secara otomatis
	for nama in daftar_nama:
		var btn = TextureButton.new()
		var path = "res://asset/ingridients/" + nama.to_lower() + ".png"
		btn.texture_normal = load(path)
		btn.expand = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED # Memaksa icon ke tengah
		btn.rect_min_size = Vector2(158, 158) # Ukuran kotak rak
		
		# Hubungkan tombol ke fungsi spawn
		btn.connect("button_down", self, "_on_rak_diklik", [nama, path])
		$IngredientsGrid.add_child(btn) # Masukkan ke grid
		
	# Sembunyikan semua NPC dulu
	$Recipe/NextPage.connect("pressed", self, "_on_NextPage_pressed")
	$BtnBukaResep.connect("pressed", self, "_on_BtnBukaResep_pressed")
	$Recipe/PrevPage.connect("pressed", self, "_on_PrevPage_pressed")
	day_popup.get_node("VBoxContainer/ContinueButton").connect("pressed", self, "_on_ContinueButton_pressed")
	day_popup.get_node("VBoxContainer/MapButton").connect("pressed", self, "_on_MapButton_pressed")
	
	# Pastikan popup tertutup saat mulai
	day_popup.hide()
	dark_overlay.hide()
	food_result_display.hide()
	recipe_book_ui.hide()
	buka_halaman(0)
	update_recipe_book_visuals()
	mulai_pesanan_baru()
func mulai_pesanan_baru():
	# 1. Sembunyikan semua NPC & Bubble
	for i in range(1, 7):
		order_ui.get_node("Npc" + str(i)).hide()
	$Order/Control/OrderBubble.hide()
	
	# 2. Cek jumlah pelanggan
	if customer_count >= max_customers:
		tampilkan_popup_hari_selesai()
		return

	# 3. Pilih NPC & Munculkan
	var npc_random = order_ui.get_node("Npc" + str(randi() % 6 + 1))
	npc_random.show()
	customer_count += 1
	
	# 4. Ambil Resep
	if GameData.owned_recipes.size() > 0:
		resep_target_nama = GameData.owned_recipes[randi() % GameData.owned_recipes.size()]
		
		# Ambil data resep
		var data_resep = GameData.get_recipe_by_name(resep_target_nama)
		
		# --- SAFETY CHECK: Jika data_resep null, berhenti di sini agar tidak crash ---
		if data_resep == null:
			print("CRASH AVOIDED: Data resep null untuk: ", resep_target_nama)
			return
		
		# Olah bahan
		var raw_list = data_resep["ing"].split(",")
		bahan_target_list = []
		for item in raw_list:
			bahan_target_list.append(item.strip_edges())
		
		# --- TAMPILKAN ORDER BUBBLE ---
		var bubble = $Order/Control/OrderBubble
		bubble.get_node("FoodLabel").text = resep_target_nama
		bubble.rect_pivot_offset = bubble.rect_size / 2 # PENTING!
		
		# Gambar makanan
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
	# Buat bahan baru saat icon di rak ditekan
	var new_item = ingredient_scene.instance()
	add_child(new_item)
	new_item.global_position = get_global_mouse_position()
	new_item.setup_bahan(nama, path)

func tambah_bahan_ke_list(nama, pos_jatuh):
	# Cek apakah jatuh di area sukses atau sampah
	# (Asumsi kamu menamai CollisionShape paling bawah sebagai 'SuccessArea')
	if pos_jatuh.y > 600: # Contoh angka koordinat area bawah panci
		bahan_di_panci.append(nama)
		print("Isi Panci: ", bahan_di_panci)
	else:
		print("Bahan terbuang ke samping!") #

func _on_Spoon_pressed():
	# Jangan masak kalau panci kosong
	if bahan_di_panci.size() == 0:
		print("Panci kosong, tidak bisa mengaduk!")
		return
	
	# Matikan tombol sementara agar tidak terjadi spam klik selama animasi
	$Spoon.disabled = true
	
	# 1. Animasi Start
	$TitleChar.play("start")
	yield($TitleChar, "animation_finished")
	
	# 2. Animasi Loop (diulang 2 kali)
	for i in range(2):
		$TitleChar.play("loop")
		yield($TitleChar, "animation_finished")
		print("Sedang mengaduk... Loop ke-", i+1)
	
	# 3. Animasi Finish
	$TitleChar.play("finish")
	yield($TitleChar, "animation_finished")
	
	# Kembali ke animasi diam (idle) jika ada
	if $TitleChar.frames.has_animation("idle"):
		$TitleChar.play("idle")
	
	# 4. Setelah selesai animasi, baru cek hasilnya
	cek_hasil_masakan()
	
	# Aktifkan kembali tombol spoon
	$Spoon.disabled = false
	
func cek_hasil_masakan():
	# Sort dulu biar pembandingannya akurat
	var panci_sort = Array(bahan_di_panci) 
	panci_sort.sort()
	
	var target_sort = Array(bahan_target_list)
	target_sort.sort()
	
	print("Mencocokkan: ", panci_sort, " dengan ", target_sort)

	# --- KONDISI 1: BENAR (Sesuai Pesanan) ---
	if panci_sort == target_sort:
		print("MASAKAN BERHASIL!")
		var clean_name = resep_target_nama.to_lower().replace(" ", "_")
		var path = "res://asset/food/" + clean_name + ".png"
		
		# Panggil fungsi animasi (false = tidak gelap)
		yield(tampilkan_animasi_hasil(path, false), "completed")
		
		bahan_di_panci.clear()
		pindah_ke_customer_selanjutnya()
		
	# --- KONDISI LAIN (SALAH) ---
	else:
		print("MASAKAN SALAH!")
		
		# Cek: Sebenernya dia masak apa sih?
		var masakan_terbuat = cari_masakan_dari_isi_panci()
		
		# --- KONDISI 2: SALAH ORDER (Tapi Resep Valid & Sudah Punya) ---
		if masakan_terbuat != null and masakan_terbuat in GameData.owned_recipes:
			print("Salah order! Player malah bikin: ", masakan_terbuat)
			
			var clean_name = masakan_terbuat.to_lower().replace(" ", "_")
			var path = "res://asset/food/" + clean_name + ".png"
			
			# Tampilkan makanan tapi GELAP (true)
			yield(tampilkan_animasi_hasil(path, true), "completed")
			
		# --- KONDISI 3: SAMPAH (Ngawur / Belum Punya Resep) ---
		else:
			print("Jadi sampah (Kombinasi ngawur atau resep belum di-unlock)")
			var path_trash = "res://asset/food/trash.png" 
			# Pastikan kamu punya file trash.png di folder asset/food/
			
			# Tampilkan sampah (false = warna normal sampah)
			yield(tampilkan_animasi_hasil(path_trash, false), "completed")
		
		# Reset panci supaya player bisa coba lagi (Customer tidak ganti)
		bahan_di_panci.clear()

func pindah_ke_customer_selanjutnya():
	bahan_di_panci.clear()
	# 1. Bersihkan visual pelanggan sebelumnya
	for npc in order_ui.get_children():
		if npc is Sprite: npc.hide()
	$Order/Control/OrderBubble.hide()
	
	# 2. Cek apakah sudah mencapai batas 5 pelanggan
	if customer_count >= max_customers:
		tampilkan_popup_hari_selesai()
	else:
		# Jika belum 5, lanjut pelanggan berikutnya
		mulai_pesanan_baru()

func tampilkan_popup_hari_selesai():
	day_popup.show()
	# Beri sedikit animasi agar pop-up terasa hidup
	day_popup.rect_scale = Vector2(0, 0)
	day_popup.rect_pivot_offset = day_popup.rect_size / 2
	var tween = create_tween()
	tween.tween_property(day_popup, "rect_scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	print("Hari selesai! Muncul pop-up.")
	
# Tombol LANJUT (Reset hitungan dan mulai dari pelanggan 1 lagi)
func _on_ContinueButton_pressed():
	customer_count = 0
	day_popup.hide()
	mulai_pesanan_baru()
	print("Memulai hari baru di Kitchen.")

# Tombol KEMBALI KE MAP
func _on_MapButton_pressed():
	# Jika ingin menyimpan progress hari di GameData, bisa tambahkan:
	# GameData.total_days_passed += 1
	FX.play_slow()
	get_tree().change_scene("res://Scene/Map.tscn")
	# --- Navigasi Halaman Selanjutnya ---
func _on_NextPage_pressed():
	if is_busy or current_page_index >= pages.size() - 1: return
	
	is_busy = true
	$Recipe/Pages.hide()
	
	$Recipe/Book_animated.speed_scale = 1.0
	$Recipe/Book_animated.frame = 0
	$Recipe/Book_animated.play("next")
	
	# Tunggu 0.4 detik (sesuaikan dengan durasi animasi kamu)
	yield(get_tree().create_timer(0.4), "timeout")
	
	current_page_index += 1
	buka_halaman(current_page_index)
	$Recipe/Pages.show()
	is_busy = false

# --- Navigasi Halaman Sebelumnya ---
func _on_PrevPage_pressed():
	if is_busy or current_page_index <= 0: 
		return
	
	is_busy = true
	$Recipe/Pages.hide()
	
	
	# 3. Mainkan animasinya
	$Recipe/Book_animated.speed_scale = 1.0
	$Recipe/Book_animated.frame = 0
	$Recipe/Book_animated.play("prev")
	
	# 4. Tunggu timer (sesuaikan dengan durasi animasi, misal 0.4 detik)
	yield(get_tree().create_timer(0.4), "timeout")
	
	# --- RESET SETELAH SELESAI ---
	
	current_page_index -= 1
	buka_halaman(current_page_index)
	$Recipe/Pages.show()
	
	is_busy = false
func buka_halaman(index):
	current_page_index = index
	
	# Memastikan halaman ganti
	for i in range(pages.size()):
		if pages[i] != null:
			pages[i].visible = (i == index)
	
	# --- PERBAIKAN PATH DI SINI ---
	# Gunakan get_node_or_null agar tidak crash jika path salah
	var btn_prev = get_node_or_null("Recipe/PrevPage") 
	var btn_next = get_node_or_null("Recipe/NextPage")
	
	# Jika ternyata tombolnya ada di root Kitchen, gunakan ini:
	if btn_prev == null: btn_prev = get_node_or_null("PrevPage")
	if btn_next == null: btn_next = get_node_or_null("NextPage")

	# Set visibilitas hanya jika node-nya ketemu
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
					slot.modulate = Color(1, 1, 1) # Terang (Terbuka)
					
					# 1. Set Nama Makanan
					slot.get_node("FoodName").text = nama_resep
					
					# 2. Set Gambar Makanan (Asumsi nama file = nama makanan di-lower case)
					var food_path = "res://asset/food/" + nama_resep.to_lower().replace(" ", "_") + ".png"
					if File.new().file_exists(food_path):
						slot.get_node("FoodIcon").texture = load(food_path)
					
					# 3. Set Nama Bahan (Teks)
					slot.get_node("IngLabel").text = data["ing"].replace(",", " +")
					
					# 4. Generate Ikon Bahan di IngContainer
					var container = slot.get_node("IngContainer")
					# Bersihkan ikon lama dulu
					for child in container.get_children():
						child.queue_free()
					
					# Ambil list bahan ["Air", "Sayur"]
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
					# Tampilan jika resep masih terkunci
					slot.modulate = Color(0.2, 0.2, 0.2) # Gelap
					slot.get_node("FoodName").text = "???"
					slot.get_node("IngLabel").text = "Terkunci"
					# Hapus gambar/ikon jika ada
					slot.get_node("FoodIcon").texture = null
					for child in slot.get_node("IngContainer").get_children():
						child.queue_free()
func _on_BtnBukaResep_pressed():
	if is_busy: return
	
	is_busy = true
	
	if recipe_book_ui.visible:
		# --- PROSES TUTUP ---
		var tween = create_tween()
		tween.tween_property(dark_overlay, "modulate:a", 0.0, 0.3)
		yield(tween, "finished")
		dark_overlay.hide()
		# Langsung sembunyikan konten agar tidak "melayang" saat buku menutup
		$Recipe/Pages.hide()
		$Recipe/NextPage.hide()
		$Recipe/PrevPage.hide()
		
		$Recipe/Book_animated.play("close")
		yield(get_tree().create_timer(0.7), "timeout") # Sesuaikan dengan durasi animasi close
		
		recipe_book_ui.hide()
	else:
		# --- PROSES BUKA ---
		dark_overlay.show()
		dark_overlay.modulate.a = 0
		var tween=create_tween()
		tween.tween_property(dark_overlay, "modulate:a", 0.55, 0.3)
		update_recipe_book_visuals()
		
		# Pastikan konten dalam keadaan SEMBUNYI sebelum buku terbuka
		$Recipe/Pages.hide()
		$Recipe/NextPage.hide()
		$Recipe/PrevPage.hide()
		
		recipe_book_ui.show()
		$Recipe/Book_animated.play("open")
		
		# TUNGGU sampai animasi buka selesai
		yield(get_tree().create_timer(0.5), "timeout") # Sesuaikan durasi (misal 0.5 detik)
		
		# BARU TAMPILKAN konten dan navigasi
		$Recipe/Pages.show()
		buka_halaman(current_page_index) # Fungsi ini otomatis mengatur show/hide tombol Next/Prev
		
	is_busy = false

# Fungsi untuk mencari nama masakan berdasarkan isi panci
func cari_masakan_dari_isi_panci():
	var bahan_sekarang = Array(bahan_di_panci)
	bahan_sekarang.sort()
	
	# Loop ke seluruh database resep di GameData
	var db = GameData.recipe_database
	for mapel in db.keys():
		for diff in db[mapel].keys():
			var data = db[mapel][diff]
			
			# Ambil bahan dari database dan rapikan
			var bahan_resep = data["ing"].split(",")
			var target_sort = []
			for b in bahan_resep:
				target_sort.append(b.strip_edges())
			target_sort.sort()
			
			# Bandingkan
			if bahan_sekarang == target_sort:
				return data["name"] # Ketemu! Kembalikan nama masakannya
	
	return null # Tidak ketemu resep apapun (Masakan ngawur)
func tampilkan_animasi_hasil(texture_path, is_darkened):
	# 1. Load Gambar
	if File.new().file_exists(texture_path):
		food_result_display.texture = load(texture_path)
	else:
		print("Gambar tidak ditemukan: ", texture_path)
		return

	# 2. Atur Warna (Normal atau Gelap)
	if is_darkened:
		food_result_display.modulate = Color(0.4, 0.4, 0.4, 1) # Gelap
	else:
		food_result_display.modulate = Color(1, 1, 1, 1) # Normal

	# 3. Reset Properti Animasi
	food_result_display.show()
	food_result_display.rect_pivot_offset = food_result_display.rect_size / 2
	food_result_display.rect_scale = Vector2(0, 0)
	
	# 4. Mainkan Animasi Pop-Up
	var tween = create_tween()
	tween.tween_property(food_result_display, "rect_scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(food_result_display, "rect_scale", Vector2(1.0, 1.0), 0.1)
	
	# 5. Tahan (Freeze)
	yield(get_tree().create_timer(2.0), "timeout")
	
	# 6. Sembunyikan (Pop-Out)
	var close_tween = create_tween()
	close_tween.tween_property(food_result_display, "rect_scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	yield(close_tween, "finished")
	
	food_result_display.hide()
	food_result_display.modulate = Color(1, 1, 1, 1) # Reset warna jaga-jaga
