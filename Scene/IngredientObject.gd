extends Node2D

var nama_bahan = "" 
var is_dragging = false

func _ready():
	add_to_group("Ingredients")
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
	
	var target_dimensi = 158.0
	var original_size = tex.get_size()
	var max_side = max(original_size.x, original_size.y)
	var scale_factor = target_dimensi / max_side
	$Sprite.scale = Vector2(scale_factor, scale_factor)
	
	is_dragging = true
	z_index = 10

func _input(event):
	if event is InputEventMouseButton and not event.pressed:
		if is_dragging:
			cek_lokasi_jatuh()

func cek_lokasi_jatuh():
	is_dragging = false 
	if not get_parent().has_node("PotArea"):
		print("ERROR: Node 'PotArea' tidak ditemukan di Kitchen!")
		animasi_buang()
		return
	var pot = get_parent().get_node("PotArea") 
	
	var pot_x_center = pot.global_position.x
	var target_y = pot.global_position.y + 120 
	
	var lebar_lubang = 100.0 
	
	if abs(global_position.x - pot_x_center) < lebar_lubang:
		animasi_jatuh_ke_panci(target_y)
		get_parent().tambah_bahan_ke_list(nama_bahan, Vector2(global_position.x, target_y))
	else:
		animasi_buang()

func animasi_jatuh_ke_panci(pos_y_target):
	z_index = 4 
	
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", pos_y_target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", Vector2(0, 0), 0.4)
	tween.parallel().tween_property(self, "modulate:a", 0, 0.4)
	
	yield(tween, "finished")
	queue_free()

func animasi_buang():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.3)
	yield(tween, "finished")
	queue_free()

func _on_area_entered(area):
	if area.name == "VisualPotArea":
		z_index = 4
	if area.name == "PotArea":
		z_index = 10

func _on_area_exited(area):
	if area.name == "VisualPotArea":
		z_index = 10
