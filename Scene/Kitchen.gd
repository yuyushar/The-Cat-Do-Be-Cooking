extends Control

# Memuat template bahan
onready var ingredient_scene = preload("res://Scene/IngredientObject.tscn")
var bahan_di_panci = [] # List untuk menampung bahan yang masuk
var resep_target_nama = ""
var bahan_target_list = []
var customer_count = 0
var max_customers = 5

onready var order_ui = $Order/Control # Mengacu pada susunan NPC kamu
onready var order_label = $Order/Control/Label # Asumsi ada Label untuk nama pesanan
onready var recipe_book_ui = $Recipe # Node parent buku resep
var current_page_index = 0
onready var pages = [
	$Recipe/Pages/Page_Biologi,
	$Recipe/Pages/Page_Fisika,
	$Recipe/Pages/Page_Kimia,
	$Recipe/Pages/Page_Matematika
]

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
	
	recipe_book_ui.hide()
	buka_halaman(0)
	mulai_pesanan_baru()
func mulai_pesanan_baru():
	for i in range(1, 7):
		order_ui.get_node("Npc" + str(i)).hide()
		
	var npc_random = order_ui.get_node("Npc" + str(randi() % 6 + 1))
	npc_random.show()
	if customer_count >= max_customers:
		print("Semua pelanggan hari ini selesai!")
		return
	
	bahan_di_panci.clear() # Kosongkan panci untuk pelanggan baru
	customer_count += 1
	
	
	# 2. Ambil Resep yang sudah dimiliki dari GameData
	if GameData.owned_recipes.size() > 0:
		# Pilih resep acak dari yang sudah di-unlock di Library
		resep_target_nama = GameData.owned_recipes[randi() % GameData.owned_recipes.size()]
		
		# Cari detail bahan dari database berdasarkan nama resep
		# Kita butuh fungsi pembantu di GameData untuk mencari detail berdasarkan NAMA saja
		var data_resep = GameData.get_recipe_by_name(resep_target_nama)
		bahan_target_list = data_resep["ing"].split(",") # Jadikan array
		for i in range(bahan_target_list.size()):
			bahan_target_list[i] = bahan_target_list[i].strip_edges()
		
		print("Pelanggan minta: ", resep_target_nama)
		# Tampilkan di Order Bubble (Gelembung Pesanan)
		# order_label.text = resep_target_nama 
	else:
		print("Player belum punya resep apapun!")

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
	# Karena urutan masuk bahan bisa berbeda, kita urutkan (sort) dulu keduanya
	var panci_sort = bahan_di_panci.duplicate()
	panci_sort.sort()
	
	var target_sort = bahan_target_list.duplicate()
	target_sort.sort()
	
	if panci_sort == target_sort:
		print("MASAKAN BERHASIL!")
		# Tambahkan animasi makanan muncul atau NPC senang
		yield(get_tree().create_timer(1.5), "timeout")
		pindah_ke_customer_selanjutnya()
	else:
		print("MASAKAN SALAH!")
		# Beri feedback kalau salah
		bahan_di_panci.clear() # Player harus ulang masukin bahan

func pindah_ke_customer_selanjutnya():
	# Sembunyikan NPC yang sekarang
	for npc in order_ui.get_children():
		if npc is Sprite: npc.hide()
	
	mulai_pesanan_baru()
func _on_NextPage_pressed():
	if $Recipe/Book_animated.is_playing(): return
	
	# 1. Animasi Balik Halaman (Normal)
	$Recipe/Book_animated.speed_scale = 1.0
	$Recipe/Book_animated.play("next")
	print("next dipencet")
	
	# 2. Sembunyikan teks sebentar agar tidak terlihat saat transisi
	$Recipe/Pages.hide()
	
	yield($Recipe/Book_animated, "animation_finished")
	
	# 3. Update Index Halaman
	current_page_index = (current_page_index + 1) % pages.size()
	buka_halaman(current_page_index)
	$Recipe/Pages.show()

# Fungsi Navigasi Halaman Sebelumnya
func _on_PrevPage_pressed():
	if $Recipe/Book_animated.is_playing(): return
	
	$Recipe/Pages.hide()
	
	# Memutar animasi 'next' secara terbalik
	# Di Godot 3.x:
	$Recipe/Book_animated.speed_scale = -1.0
	var last_frame = $Recipe/Book_animated.frames.get_frame_count("next") - 1
	$Recipe/Book_animated.frame = last_frame
	$Recipe/Book_animated.play("next")
	
	yield($Recipe/Book_animated, "animation_finished")
	
	# Reset speed ke normal
	$Recipe/Book_animated.speed_scale = 1.0
	
	current_page_index = (current_page_index - 1 + pages.size()) % pages.size()
	buka_halaman(current_page_index)
	$Recipe/Pages.show()
func buka_halaman(index):
	current_page_index = index
	for i in range(pages.size()):
		pages[i].visible = (i == index)

# Fungsi Update Visual (Gelap/Terang)
func update_recipe_book_visuals():
	var db = GameData.recipe_database
	
	for mapel in db.keys():
		for diff in db[mapel].keys():
			var data = db[mapel][diff]
			var nama_resep = data["name"]
			
			# Jalur sekarang mengarah ke: Recipe/Pages/Page_.../Slot_...
			var slot_path = "Recipe/Pages/Page_" + mapel + "/Slot_" + diff
			
			if has_node(slot_path): # Cek apakah nodenya ada
				var slot = get_node(slot_path)
				
				if nama_resep in GameData.owned_recipes:
					slot.modulate = Color(1, 1, 1) # Terang
					slot.get_node("Nama").text = nama_resep
					slot.get_node("Bahan").text = data["ing"].replace(",", " +")
				else:
					slot.modulate = Color(0.2, 0.2, 0.2) # Gelap
					slot.get_node("Nama").text = "???"
					slot.get_node("Bahan").text = "Belum Terbuka"

func _on_BtnBukaResep_pressed():
		# Jika animasi sedang jalan, abaikan klik agar tidak error
	if $Recipe/Book_animated.is_playing(): 
		return

	if recipe_book_ui.visible:
		# --- PROSES TUTUP ---
		$Recipe/Pages.hide()
		if has_node("Recipe/NextPage"): $Recipe/NextPage.hide()
		if has_node("Recipe/PrevPage"): $Recipe/PrevPage.hide()
		
		$Recipe/Book_animated.play("close")
		yield($Recipe/Book_animated, "animation_finished")
		recipe_book_ui.hide()
		print("Buku ditutup")
	else:
		# --- PROSES BUKA ---
		update_recipe_book_visuals()
		recipe_book_ui.show()
		
		$Recipe/Book_animated.play("open")
		yield($Recipe/Book_animated, "animation_finished")
		
		# Tampilkan halaman dan tombol navigasi setelah animasi buka selesai
		$Recipe/Pages.show()
		if has_node("Recipe/NextPage"): $Recipe/NextPage.show()
		if has_node("Recipe/PrevPage"): $Recipe/PrevPage.show()
		buka_halaman(current_page_index)
		print("Buku dibuka")
		

