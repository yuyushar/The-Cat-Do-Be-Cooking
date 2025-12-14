extends Node2D

var nama_bahan = "" 
var is_dragging = false

func _ready():
	add_to_group("Ingredients")
	# Pastikan sinyal terhubung untuk layering visual saat drag
	if has_node("Area2D"):
		$Area2D.connect("area_entered", self, "_on_area_entered")
		$Area2D.connect("area_exited", self, "_on_area_exited")

func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position() 

func setup_bahan(nama, texture_path):
	nama_bahan = nama
	var tex = load(texture_path)
	$Sprite.texture = tex
	
	# Scaling agar ukuran seragam 158px
	var target_dimensi = 158.0
	var original_size = tex.get_size()
	var max_side = max(original_size.x, original_size.y)
	var scale_factor = target_dimensi / max_side
	$Sprite.scale = Vector2(scale_factor, scale_factor)
	
	is_dragging = true
	z_index = 10 # Di depan segalanya saat awal drag

func _input(event):
	if event is InputEventMouseButton and not event.pressed:
		if is_dragging:
			# KUNCI: Panggil fungsi lokasi jatuh, bukan area jatuh
			cek_lokasi_jatuh()

func cek_lokasi_jatuh():
	is_dragging = false 
	
	# Ambil referensi PotArea di Kitchen
	# Asumsi IngredientObject adalah anak langsung dari Kitchen
	var pot = get_parent().get_node("PotArea") 
	
	var pot_x_center = pot.global_position.x
	# Target jatuh ke dasar panci (Y panci + offset ke bawah)
	var target_y = pot.global_position.y + 120 
	
	# Toleransi lebar lubang panci
	var lebar_lubang = 100.0 
	
	# Cek apakah X bahan berada di dalam area mulut panci
	if abs(global_position.x - pot_x_center) < lebar_lubang:
		# SUKSES: Jalankan animasi jatuh
		animasi_jatuh_ke_panci(target_y)
		# Kirim posisi jatuh ke Kitchen
		get_parent().tambah_bahan_ke_list(nama_bahan, Vector2(global_position.x, target_y))
	else:
		# GAGAL: Terbuang ke samping
		animasi_buang()

func animasi_jatuh_ke_panci(pos_y_target):
	# Pindah ke belakang bibir panci (PotFront Z=5)
	z_index = 4 
	
	var tween = create_tween()
	# Animasi jatuh ke bawah
	tween.tween_property(self, "global_position:y", pos_y_target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Sambil mengecil agar seolah masuk ke dalam air
	tween.parallel().tween_property(self, "scale", Vector2(0, 0), 0.4)
	tween.parallel().tween_property(self, "modulate:a", 0, 0.4)
	
	yield(tween, "finished")
	queue_free()

func animasi_buang():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.3)
	yield(tween, "finished")
	queue_free()

# --- Layering Visual saat Drag ---
func _on_area_entered(area):
	if area.name == "VisualPotArea" or area.name == "PotArea":
		z_index = 4 # Masuk ke belakang bibir panci

func _on_area_exited(area):
	if area.name == "VisualPotArea" or area.name == "PotArea":
		z_index = 10 # Keluar ke depan lagi
