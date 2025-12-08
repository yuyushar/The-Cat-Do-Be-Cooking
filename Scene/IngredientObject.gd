extends Node2D

var nama_bahan = "" # Nanti diisi saat spawn (misal: "Daging")
var is_dragging = false
var original_position = Vector2.ZERO # Posisi awal untuk balik kalau gagal
var target_pot = null # Menyimpan referensi panci

func _ready():
	# Simpan posisi awal saat muncul
	original_position = global_position
	
	# Koneksi tombol klik
	$ClickButton.connect("button_down", self, "_on_clicked")
	$ClickButton.connect("button_up", self, "_on_released")

func setup(nama, texture_path):
	nama_bahan = nama
	$Sprite.texture = load(texture_path)

func _process(delta):
	if is_dragging:
		# Bahan mengikuti posisi mouse
		global_position = get_global_mouse_position()

func _on_clicked():
	is_dragging = true
	scale = Vector2(1.2, 1.2) # Efek membesar dikit pas diangkat
	z_index = 10 # Supaya gambarnya ada di paling depan (di atas panci dll)

func _on_released():
	is_dragging = false
	scale = Vector2(1, 1) # Balik ukuran normal
	z_index = 0
	
	# Cek apakah kita sedang berada di atas panci?
	# Logic ini ditangani oleh Area2D Panci (lihat script PotArea di atas)
	
	# Beri jeda sedikit, kalau tidak masuk panci, balik ke rak
	yield(get_tree().create_timer(0.1), "timeout")
	if target_pot == null:
		return_to_shelf()

# Fungsi dipanggil oleh Panci jika bahan berhasil masuk
func snap_to_pot(pot_node):
	target_pot = pot_node
	
	# Matikan interaksi
	$ClickButton.disabled = true
	
	# Animasi masuk ke panci (mengecil dan hilang)
	var tween = create_tween()
	tween.tween_property(self, "global_position", pot_node.global_position, 0.2)
	tween.parallel().tween_property(self, "scale", Vector2(0,0), 0.2)
	yield(tween, "finished")
	
	# Masukkan data ke panci
	pot_node.add_ingredient_data(nama_bahan)
	
	# Hapus objek bahan ini
	queue_free()

func return_to_shelf():
	# Animasi balik ke tempat asal
	var tween = create_tween()
	tween.tween_property(self, "global_position", original_position, 0.3).set_trans(Tween.TRANS_BACK)
