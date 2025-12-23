extends Control

onready var hover_label = $HoverLabel
onready var ui_blocker = $UIBlocker
# Referensi Node baru sesuai gambar
onready var result_popup = $QuizUI/ResultPopup
onready var bad_end_node = $QuizUI/bad_end
onready var bad_end2_node = $QuizUI/bad_end2
# Variabel Game
var health = 3
var total_questions = 0
var current_question_index = 0
var current_questions_list = [] # List soal yang sedang dimainkan
var current_mapel = ""
var current_difficulty = ""
var origin_bar_y = 0
var origin_cat_x = 0
var origin_question_x = 0
var origin_answers_x = 0
var origin_explanation_y = 0
func _ready():
	# Setup Awal
	$BackToMenu.show()
	$BookUI.hide()
	$QuizUI.hide()
	result_popup.hide()
	bad_end_node.hide()
	
	# Koneksi Tombol Menu
	$BackToMenu.connect("pressed", self, "Menupressed")
	$BookUI/BackButton.connect("pressed", self, "_on_book_back_pressed")

	# Koneksi Tombol Difficulty
	$BookUI/DifficultyMenu/EasyButton.connect("pressed", self, "_on_difficulty_selected", ["Easy"])
	$BookUI/DifficultyMenu/MediumButton.connect("pressed", self, "_on_difficulty_selected", ["Medium"])
	$BookUI/DifficultyMenu/HardButton.connect("pressed", self, "_on_difficulty_selected", ["Hard"])

	# Koneksi Tombol Jawaban (A, B, C, D)
	var answer_buttons = $QuizUI.get_node("Answer Button")
	answer_buttons.get_node("A").connect("pressed", self, "_on_answer_pressed", ["A"])
	answer_buttons.get_node("B").connect("pressed", self, "_on_answer_pressed", ["B"])
	answer_buttons.get_node("C").connect("pressed", self, "_on_answer_pressed", ["C"])
	answer_buttons.get_node("D").connect("pressed", self, "_on_answer_pressed", ["D"])

	# Koneksi Tombol Bad End (Retry & Return)
	bad_end_node.get_node("ReturnButton").connect("pressed", self, "_on_book_back_pressed") # Balik ke rak
	bad_end_node.get_node("RetryButton").connect("pressed", self, "_retry_quiz") # Ulang quiz

	# Koneksi Tombol Result Popup (Menang)
	# ASUMSI: Di dalam ResultPopup ada tombol 'KitchenButton' dan 'BackLibraryButton'
	# Ganti nama node di bawah sesuai isi scene ResultPopup kamu
	if result_popup.has_node("KitchenButton"):
		result_popup.get_node("KitchenButton").connect("pressed", self, "_goto_kitchen")
	if result_popup.has_node("BackLibraryButton"):
		result_popup.get_node("BackLibraryButton").connect("pressed", self, "_on_book_back_pressed")

	# Setup Rak Buku
	hover_label.hide()
	var mapel = ["Biologi", "Fisika", "Kimia", "Matematika"]
	for i in range($ShelfButton.get_child_count()):
		var shelf = $ShelfButton.get_child(i)
		shelf.connect("mouse_entered", self, "_on_shelf_entered", [shelf, mapel[i]])
		shelf.connect("mouse_exited", self, "_on_shelf_exited")
		shelf.connect("pressed", self, "_on_shelf_pressed", [shelf, mapel[i]])
	origin_bar_y = $ProgressBar.rect_position.y
	origin_cat_x = 138
	origin_question_x = $QuizUI/QuestionLabel.rect_position.x
	origin_answers_x = $QuizUI.get_node("Answer Button").rect_position.x
	origin_explanation_y = $QuizUI/ExplanationLabel.rect_position.y
	$QuizManager.load_json()

# --- LOGIKA PILIH RAK & BUKA BUKU ---
func _on_shelf_pressed(shelf, mapel):
	current_mapel = mapel # Simpan mapel yang dipilih
	$BackToMenu.hide()
	ui_blocker.show()
	$BackToMenu.disabled = true
	
	# Animasi Buku
	$Book_animated.position.y = 1000
	create_tween().tween_property($Book_animated, "position:y", 357, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	$ShelfButton.modulate.a = 0.3
	$Background.modulate.a = 0.3
	$Book_animated.show()
	$Book_animated.frame=0
	$Book_animated.play("open")
	yield($Book_animated, "animation_finished")
	
	show_difficulty_menu()

func show_difficulty_menu():
	$BookUI.show()
	var menu = $BookUI/DifficultyMenu
	menu.show()
	
	# Cek Lock/Unlock status dari GameData
	var unlocked_level = GameData.difficulty_progress[current_mapel]
	
	# 0=Easy, 1=Medium, 2=Hard
	menu.get_node("EasyButton").disabled = false
	menu.get_node("MediumButton").disabled = (unlocked_level < 1)
	menu.get_node("HardButton").disabled = (unlocked_level < 2)
	
	# Visual feedback kalau disable (opsional, misal jadi gelap)
	menu.get_node("MediumButton").modulate = Color(1,1,1) if unlocked_level >= 1 else Color(0.5,0.5,0.5)
	menu.get_node("HardButton").modulate = Color(1,1,1) if unlocked_level >= 2 else Color(0.5,0.5,0.5)

	# Animasi tombol muncul
	var buttons = [menu.get_node("EasyButton"), menu.get_node("MediumButton"), menu.get_node("HardButton")]
	for i in range(buttons.size()):
		var btn = buttons[i]
		btn.modulate.a = 0
		btn.rect_position.y += 40
		var tween = create_tween()
		tween.tween_property(btn, "modulate:a", 1, 0.4).set_delay(i * 0.1)
		tween.tween_property(btn, "rect_position:y", btn.rect_position.y - 40, 0.4).set_delay(i * 0.1)

# --- LOGIKA MULAI QUIZ ---
func _on_difficulty_selected(level):
	current_difficulty = level
	
	# Ambil soal dari QuizManager
	current_questions_list = $QuizManager.get_questions(current_mapel, level)

	if current_questions_list.size() == 0:
		print("Soal kosong!")
		return

	# Set jumlah soal berdasarkan level
	match level:
		"Easy": total_questions = 3
		"Medium": total_questions = 5
		"Hard": total_questions = 7
	
	# Potong list soal sesuai jumlah yang dibutuhkan
	if current_questions_list.size() > total_questions:
		current_questions_list.resize(total_questions)

	# Reset Stat Quiz
	$ProgressBar.max_value = total_questions
	$ProgressBar.value = 0
	
	$ProgressCat1.position.x = 138
	current_question_index = 0
	health = 3
	
	# UI Transisi
	$BookUI.hide()
	var hearts = $QuizUI/Hearts.get_children()
	for h in hearts:
		# Hentikan tween lama jika masih jalan (penting!)
		if h.get_node_or_null("Tween"): 
			h.get_node("Tween").stop_all() # Jika kamu pakai node Tween di dalam hati
		
		h.modulate = Color(1, 1, 1) # Kembalikan warna (tidak transparan)
		h.rect_position.y = 0       # PAKSA TURUN KE POSISI AWAL
	show_quiz_ui_animation()
	$ProgressBar.show()
	$ProgressCat1.show()
	$ProgressCat1.play("default")
	$ProgressCat1.speed_scale = 1.0
	$QuizUI.show()
	$QuizUI/Light.hide()        # Pastikan cahaya mati
	result_popup.hide()         # Pastikan popup menang mati
	bad_end_node.hide()
	$QuizUI/QuestionLabel.show()         
	$QuizUI.get_node("Answer Button").show()
	$QuizUI/Hearts.show()
	$QuizUI/ExplanationLabel.hide()
	# Tampilkan soal pertama
	var btns = $QuizUI.get_node("Answer Button")
	for child in btns.get_children():
		child.disabled = false  # <--- INI KUNCINYA
		child.pressed = false   # Reset status tertekan (jaga-jaga)
	load_current_question_to_ui()
	$QuizUI/QuestionLabel.modulate.a = 0
	$QuizUI.get_node("Answer Button").modulate.a = 0
	
	# Panggil Animasi Masuk
	animate_ui_in()

func load_current_question_to_ui():
	var data = current_questions_list[current_question_index]
	
	# Set Text Soal
	$QuizUI/QuestionLabel.text = data["question"]
	
	# Set Text Jawaban
	var btn_node = $QuizUI.get_node("Answer Button")
	var options = data["options"] # Ini adalah Array ["A. ...", "B. ..."]

	# Kita langsung ambil berdasarkan urutan (Index 0 = A, 1 = B, dst)
	# Menggunakan str() untuk jaga-jaga kalau ada opsi yang isinya cuma angka
	btn_node.get_node("A").text = str(options[0])
	btn_node.get_node("B").text = str(options[1])
	btn_node.get_node("C").text = str(options[2])
	btn_node.get_node("D").text = str(options[3])
func _on_answer_pressed(pilihan_user):
	var data = current_questions_list[current_question_index]
	var jawaban_benar = str(data["answer"]) # Ambil kunci jawaban dari JSON
	var btns = $QuizUI.get_node("Answer Button")
	for child in btns.get_children():
		child.disabled = true
		
	if pilihan_user.to_upper() == jawaban_benar.to_upper():
		print("Benar!")
		# Tampilkan Penjelasan Dulu
		show_explanation_sequence(data)
	else:
		print("Salah!")
		wrong_answer()
		# Nyalakan tombol lagi kalau salah (biar bisa jawab lagi/tunggu bad end)
		if health > 0:
			for child in btns.get_children():
				child.disabled = false
func show_explanation_sequence(data):
	# 1. Sembunyikan tombol jawaban sementara (opsional, atau biarkan disabled)
	var btns = $QuizUI.get_node("Answer Button")
	
	# 2. Set Teks Penjelasan
	var expl_text = "Penjelasan: " + str(data.get("Explanation", "Tidak ada penjelasan."))
	$QuizUI/ExplanationLabel.text = expl_text
	$QuizUI/ExplanationLabel.show()
	$QuizUI/ExplanationLabel.modulate.a = 0
	
	# 3. Animasi Muncul Penjelasan
	var tween = create_tween()
	tween.tween_property($QuizUI/ExplanationLabel, "modulate:a", 1, 0.5)
	
	# 4. Tunggu 3 Detik
	yield(get_tree().create_timer(3.0), "timeout")
	
	# 5. Lanjut ke Soal Berikutnya (Logika Next Pindah Kesini)
	proceed_to_next_step()
func proceed_to_next_step():
	# 1. Animasi UI KELUAR (Geser ke kiri / Hilang)
	animate_ui_out()
	
	# Tunggu animasi keluar selesai (0.5 detik)
	yield(get_tree().create_timer(0.5), "timeout")
	
	# Sembunyikan Penjelasan
	$QuizUI/ExplanationLabel.hide()

	# 2. Mainkan Animasi Buku Balik Halaman
	$Book_animated.frame = 0
	$Book_animated.play("next")
	
	# Tunggu animasi buku selesai (sesuaikan durasi animasimu)
	yield($Book_animated, "animation_finished")

	# 3. Update Data (Index tambah)
	current_question_index += 1
	$ProgressBar.value = current_question_index
	update_cat_position()

	# Cek apakah sudah selesai atau masih ada soal
	if current_question_index < total_questions:
		# Load Soal Baru ke Text (posisi masih tersembunyi/di luar layar)
		load_current_question_to_ui()
		
		# Nyalakan kembali tombol jawaban
		var btns = $QuizUI.get_node("Answer Button")
		for child in btns.get_children():
			child.disabled = false
		animate_ui_in()
		
	else:
		# Menang
		quiz_finished_win()

func next_question():
	# Animasi Next Page (Buku)
	$Book_animated.frame = 0
	$Book_animated.play("next")

	# Update Progress Bar & Kucing
	current_question_index += 1
	$ProgressBar.value = current_question_index
	update_cat_position()

	if current_question_index < total_questions:
		# Masih ada soal, load soal berikutnya
		load_current_question_to_ui()
	else:
		# SUDAH SELESAI SEMUA SOAL (MENANG)
		quiz_finished_win()
func animate_ui_in():
	var q_label = $QuizUI/QuestionLabel
	var btn_group = $QuizUI.get_node("Answer Button")
	
	# Set posisi awal (sedikit di kanan biar seolah masuk dari kanan)
	q_label.rect_position.x = origin_question_x + 50
	btn_group.rect_position.x = origin_answers_x + 50
	
	# Set transparan dulu
	q_label.modulate.a = 0
	btn_group.modulate.a = 0
	
	# Tween Masuk (Geser ke posisi asli & Muncul)
	var tween = create_tween()
	tween.set_parallel(true) # Jalankan barengan
	
	tween.tween_property(q_label, "rect_position:x", origin_question_x, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(q_label, "modulate:a", 1, 0.5)
	
	tween.tween_property(btn_group, "rect_position:x", origin_answers_x, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.1) # Delay dikit biar gantian
	tween.tween_property(btn_group, "modulate:a", 1, 0.5).set_delay(0.1)

func animate_ui_out():
	var q_label = $QuizUI/QuestionLabel
	var btn_group = $QuizUI.get_node("Answer Button")
	var expl_label = $QuizUI/ExplanationLabel
	
	# Tween Keluar (Geser ke kiri & Hilang)
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Soal geser ke kiri
	tween.tween_property(q_label, "rect_position:x", origin_question_x - 50, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(q_label, "modulate:a", 0, 0.4)
	
	# Tombol geser ke kiri
	tween.tween_property(btn_group, "rect_position:x", origin_answers_x - 50, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(btn_group, "modulate:a", 0, 0.4)
	
	# Penjelasan hilang (fade out)
	tween.tween_property(expl_label, "modulate:a", 0, 0.4)

func wrong_answer():
	if health > 0:
		health -= 1
		update_health_display()
	
	if health <= 0:
		quiz_finished_lose()

# --- KONDISI MENANG (DAPAT RESEP) ---
func quiz_finished_win():
	$ProgressCat1.speed_scale = 2.0
	yield(get_tree().create_timer(1.0), "timeout")
	update_result_popup_content()
	$ProgressBar.hide()
	$ProgressCat1.hide()
	$QuizUI/Hearts.hide()
	$QuizUI/QuestionLabel.hide()
	$QuizUI.get_node("Answer Button").hide()

	# Animasi Cahaya
	var light = $QuizUI/Light
	ui_blocker.show()
	light.show()
	light.modulate.a = 0
	light.scale = Vector2(0.5, 0.5)
	result_popup.show()
	result_popup.rect_scale = Vector2(0,0)
	
	result_popup.rect_pivot_offset = result_popup.rect_size / 2
	
	var tween_in = create_tween()
	tween_in.set_parallel(true)
	tween_in.tween_property(light, "modulate:a", 1, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(light, "scale", Vector2(3.6, 2.2), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(result_popup, "rect_scale", Vector2(1,1), 1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.2)
	$Book_animated.hide()
	yield(tween_in, "finished")
	yield(get_tree().create_timer(0.5), "timeout")
	
	# Simpan Progress & Resep
	var data = GameData.get_recipe_data(current_mapel, current_difficulty)
	var resep_baru = data["name"]
	if not resep_baru in GameData.owned_recipes:
		GameData.owned_recipes.append(resep_baru)
		print("BERHASIL: Resep " + resep_baru + " ditambahkan ke GameData!")
	GameData.unlock_next_difficulty(current_mapel, current_difficulty)	
	# Disini kamu bisa random resep atau set resep fix per level
	# GameData.owned_recipes.append("Resep Baru") 

	# Tampilkan Popup Resep


	$ShelfButton.modulate.a = 0.3
	$Background.modulate.a = 0.3
	$BackToMenu.hide()
	$BackToMenu.disabled = false
	$ProgressBar.value=0
	$ProgressCat1.position.x = 138
# --- KONDISI KALAH (BAD END) ---
func update_result_popup_content():
	# Ambil data dari GameData berdasarkan Mapel & Difficulty saat ini
	var data = GameData.get_recipe_data(current_mapel, current_difficulty)
	
	# 2. Update Teks Nama & Deskripsi
	if result_popup.has_node("FoodIcon"):
		# Ubah "Nasi Goreng" menjadi "nasi_goreng.png"
		var nama_file = data["name"].to_lower().replace(" ", "_") + ".png"
		var path = "res://asset/food/" + nama_file
		
		# Cek apakah file ada agar tidak error
		if File.new().file_exists(path):
			result_popup.get_node("FoodIcon").texture = load(path)
		else:
			print("Gambar makanan tidak ketemu: ", path)	
	if result_popup.has_node("FoodNameLabel"):
		result_popup.get_node("FoodNameLabel").text = data["name"]
	if result_popup.has_node("IngredientsLabel"): # Pastikan label ini ada
		# Mengambil data mentah: "Daging, Santan, Telur"
		var raw_text = data["ing"]
		# Mengubah koma menjadi " + " -> "Daging + Santan + Telur"
		var formatted_text = raw_text.replace(",", " +")
		result_popup.get_node("IngredientsLabel").text = formatted_text
	# 3. LOGIC GAMBAR BAHAN
	if result_popup.has_node("IngredientsContainer"):
		var container = result_popup.get_node("IngredientsContainer")
		
		# A. Bersihkan gambar lama dulu (biar ga numpuk)
		for child in container.get_children():
			child.queue_free()
		
		# B. Ambil string bahan dan pisahkan berdasarkan koma
		# Contoh: "Buah, Madu, Air" -> ["Buah", " Madu", " Air"]
		var list_bahan = data["ing"].split(",") 
		
		# C. Loop setiap bahan
		for nama_bahan_mentah in list_bahan:
			# Bersihkan spasi (misal " Madu" jadi "Madu")
			var nama_bersih = nama_bahan_mentah.strip_edges()
			
			# Path Gambar (PENTING: Pastikan nama file sama persis besar/kecil hurufnya!)
			# Asumsi ekstensi file adalah .png
			var nama_file = str(nama_bersih).to_lower()
			var path = "res://asset/ingridients/" + nama_file + ".png"
			
			# Cek apakah file ada?
			var file_check = File.new()
			if file_check.file_exists(path):
				# Buat TextureRect baru
				var texture_rect = TextureRect.new()
				texture_rect.texture = load(path)
				texture_rect.expand = true
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				
				# Atur ukuran gambar bahan (misal 64x64 pixel)
				texture_rect.rect_min_size = Vector2(120,120)
				
				# Masukkan ke Container
				container.add_child(texture_rect)
			else:
				print("Gambar tidak ditemukan untuk bahan: ", path)
func quiz_finished_lose():
	$BookUI.hide()
	$Book_animated.hide()
	$ProgressBar.hide()
	$QuizUI/Hearts.hide()
	$ProgressCat1.hide()
	$QuizUI/QuestionLabel.hide()
	$QuizUI.get_node("Answer Button").hide()
	
	# Mainkan animasi Bad End
	bad_end_node.hide()
	bad_end2_node.show()
	bad_end2_node.frame = 0
	bad_end_node.get_node("ReturnButton").hide()
	bad_end_node.get_node("RetryButton").hide()
	$QuizUI/bad_end2.play("appear")
	yield($QuizUI/bad_end2, "animation_finished")
	bad_end2_node.hide()
	bad_end_node.show()
	
	bad_end_node.get_node("ReturnButton").show()
	bad_end_node.get_node("RetryButton").show()
	_start_lose_loop()
func _start_lose_loop():
	while bad_end_node.visible:
		# Mainkan Idle
		bad_end_node.frame = 0
		bad_end_node.play("idle")
		yield(bad_end_node, "animation_finished")
		
		# Jika player sudah klik retry/keluar, hentikan loop
		if not bad_end_node.visible: 
			break
		
		# Mainkan Blink
		bad_end_node.play("blink")
		yield(bad_end_node, "animation_finished")
# --- TOMBOL INTERAKSI ---
func _retry_quiz():
	# Reset tampilan bad end
	bad_end_node.hide()
	bad_end_node.stop()
	$Book_animated.show()
	$Book_animated.frame=0
	$Book_animated.play("open")
	yield($Book_animated, "animation_finished")
	# Ulangi fungsi _on_difficulty_selected dengan level yang sama
	_on_difficulty_selected(current_difficulty)

func _goto_kitchen():
	get_tree().change_scene("res://Scene/Kitchen.tscn") # Ganti path sesuai scene kitchen kamu

func _on_book_back_pressed():
	# Reset Total UI untuk kembali ke Library Menu
	$BookUI.hide()
	$QuizUI.hide()
	$ProgressBar.hide()
	$ProgressCat1.hide()
	result_popup.hide()
	bad_end_node.hide()
	hover_label.hide()
	
	$QuizUI/QuestionLabel.show() # Reset visibility untuk next play
	$QuizUI.get_node("Answer Button").show()

	$ShelfButton.modulate.a = 1.0
	$Background.modulate.a = 1.0
	$BackToMenu.show()
	$BackToMenu.disabled = false

	if $Book_animated.is_playing(): $Book_animated.stop()
	$Book_animated.frame=0
	$Book_animated.play("close")
	yield($Book_animated, "animation_finished")
	$Book_animated.hide()
	ui_blocker.hide()

# --- FUNGSI PENDUKUNG (UI/ANIMASI) ---
func update_cat_position():
	var ratio = float($ProgressBar.value) / float($ProgressBar.max_value)
	var bar_width = $ProgressBar.rect_size.x
	var bar_pos = $ProgressBar.rect_position.x
	$ProgressCat1.position.x = bar_pos + (bar_width * ratio)

func update_health_display():
	var hearts = $QuizUI/Hearts.get_children()
	for i in range(hearts.size()):
		if i < health:
			hearts[i].modulate = Color(1, 1, 1)
		else:
			hearts[i].modulate = Color(0.6, 0.6, 0.6) # Jadi abu-abu
			# Animasi hati hilang
			create_tween().tween_property(hearts[i], "rect_position:y", -20, 0.5)

func Menupressed():
	get_tree().change_scene("res://Scene/Map.tscn")

func _on_shelf_entered(shelf, mapel):
	if not ui_blocker.visible:
		show_hover(mapel, shelf)

func _on_shelf_exited():
	hover_label.hide()

func show_hover(text, shelf_node):
	hover_label.text = text
	hover_label.show()
	# (Kode posisi hover tetap sama)
	var shelf_pos = shelf_node.rect_global_position
	var shelf_size = shelf_node.rect_size
	hover_label.rect_global_position = Vector2(
		shelf_pos.x + shelf_size.x / 2 - hover_label.rect_size.x / 2,
		shelf_pos.y + shelf_size.y + 5
	)

func show_quiz_ui_animation():
	var tween = get_tree().create_tween() 

	var bar = $ProgressBar
	var start_pos_bar = bar.rect_position.y + 100
	bar.rect_position.y = start_pos_bar
	bar.modulate.a = 0
	var t1 = $Tween.interpolate_property(bar, "rect_position:y", start_pos_bar, start_pos_bar - 100, 0.6, Tween.TRANS_BACK, Tween.EASE_OUT)
	var t2 = $Tween.interpolate_property(bar, "modulate:a", 0, 1, 0.6, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.interpolate_property($ProgressCat1, "modulate:a", 0, 1, 0.6, Tween.TRANS_LINEAR, Tween.EASE_OUT)

	var btn_next = $ProgressBar/A2
	var btn_back = $ProgressBar/A3
	for b in [btn_next, btn_back]:
		var start_pos = b.rect_position.y + 60
		b.rect_position.y = start_pos
		b.modulate.a = 0
		$Tween.interpolate_property(b, "rect_position:y", start_pos, start_pos - 60, 0.6, Tween.TRANS_BACK, Tween.EASE_OUT)
		$Tween.interpolate_property(b, "modulate:a", 0, 1, 0.6, Tween.TRANS_LINEAR, Tween.EASE_OUT)

	var hearts = $QuizUI/Hearts.get_children()
	for i in range(hearts.size()):
		var h = hearts[i]
		var start_y = h.rect_position.y - 100
		h.rect_position.y = start_y
		h.modulate.a = 0
		$Tween.interpolate_property(h, "rect_position:y", start_y, start_y + 100, 0.7 + i * 0.1, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
		$Tween.interpolate_property(h, "modulate:a", 0, 1, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT)

	$Tween.start()

func reset_state():
	health = 3
	current_question_index = 0
	total_questions = 0

	$ProgressBar.value = 0
	$ProgressCat1.position.x = 138

	$ShelfButton.modulate.a = 1
	$Background.modulate.a = 1

	$Book_animated.hide()
	$BookUI.hide()
	$QuizUI.hide()
	$ProgressBar.hide()
	$QuizUI/Hearts.hide()
	$ProgressCat1.hide()

	ui_blocker.hide()

	var hearts = $QuizUI/Hearts.get_children()
	for h in hearts:
		h.modulate = Color(1,1,1)
		h.rect_position.y = 0
	if $Book_animated.is_playing():
		$Book_animated.stop()
	$Book_animated.frame = 0
	$Book_animated.animation = ""
	bad_end2_node.hide()
	bad_end_node.hide()
