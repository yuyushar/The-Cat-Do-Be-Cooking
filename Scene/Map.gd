extends Control

var locations = {
	"MenuButton": {"label": "Rumah", "scene": "res://Scene/MainMenu.tscn"},
	"KitchenButton": {"label": "Dapur", "scene": "res://Scene/Kitchen.tscn"},
	"LibraryButton": {"label": "Perpustakaan", "scene": "res://Scene/Library.tscn"}
}
onready var blocked_popup = $BlockedPopup 
func _ready():
	$CanvasLayer.show()
	var fade = $CanvasLayer/ColorRect
	fade.modulate.a = 1.0
	var tw = get_tree().create_timer(1.0)
	create_tween().tween_property(fade,"modulate:a",0.0,1.0).set_trans(Tween.TRANS_SINE)
	yield(get_tree().create_timer(1.0), "timeout")
	$CanvasLayer.hide()
		
	for btn_name in locations.keys():
		var btn = get_node(btn_name)
		btn.connect("mouse_entered", self, "_on_btn_hover", [btn_name])
		btn.connect("mouse_exited", self, "_on_btn_exit")
		btn.connect("pressed", self, "_on_btn_pressed", [btn_name])
	
	$HoverLabel.visible = false
	$HintButton.connect("pressed", self, "_on_HintButton_pressed")
	if blocked_popup.has_node("CloseBlockButton"):
		blocked_popup.get_node("CloseBlockButton").connect("pressed", self, "_on_CloseBlockButton_pressed")
func _on_btn_hover(btn_name):
	var btn = get_node(btn_name)
	btn.rect_scale = Vector2(1.1, 1.1)
	$HoverLabel.text = locations[btn_name]["label"]
	$HoverLabel.visible = true

func _on_btn_exit():
	for btn_name in locations.keys():
		get_node(btn_name).rect_scale = Vector2(1,1)
	$HoverLabel.visible = false

func _on_btn_pressed(btn_name):
	if btn_name == "KitchenButton":
		# Cek ke GameData: Apakah list resep masih kosong?
		# Ganti 'GameData.unlocked_recipes' dengan variabel penyimpanan aslimu
		# Contoh: Jika kamu menyimpan resep di array:
		if GameData.owned_recipes.size() == 0:
			show_blocked_popup()
			return # BERHENTI DI SINI, jangan jalankan kode pindah scene di bawah
	var scene_path = locations[btn_name]["scene"]
	get_tree().change_scene(scene_path)
	$CanvasLayer.show()
	var fade = $CanvasLayer/ColorRect
	create_tween().tween_property(fade, "modulate:a", 1.0, 0.5)
	yield(get_tree().create_timer(0.5), "timeout")

func show_blocked_popup():
	blocked_popup.show()
	# Opsional: Animasi pop-up (Scale dari 0 ke 1)
	blocked_popup.rect_scale = Vector2(0, 0)
	create_tween().tween_property(blocked_popup, "rect_scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BACK)
	
func _process(delta):
	if $HoverLabel.visible:
		$HoverLabel.rect_global_position = get_viewport().get_mouse_position() + Vector2(0, -30)

func _on_CloseBlockButton_pressed():
	blocked_popup.hide()
func _on_HintButton_pressed():
	get_node("TutorialPopup").popup_centered()
