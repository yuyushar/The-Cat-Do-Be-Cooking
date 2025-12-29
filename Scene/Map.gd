extends Control

var locations = {
	"MenuButton": {"label": "Rumah", "scene": "res://Scene/MainMenu.tscn"},
	"KitchenButton": {"label": "Dapur", "scene": "res://Scene/Kitchen.tscn"},
	"LibraryButton": {"label": "Perpustakaan", "scene": "res://Scene/Library.tscn"}
}
onready var padlock = $KitchenButton/PadlockICon
func _ready():
	$CanvasLayer.show()
	var fade = $CanvasLayer/ColorRect
	fade.modulate.a = 1.0
	var tw = get_tree().create_timer(1.0)
	create_tween().tween_property(fade,"modulate:a",0.0,1.0).set_trans(Tween.TRANS_SINE)
		
	for btn_name in locations.keys():
		var btn = get_node(btn_name)
		btn.rect_pivot_offset = btn.rect_size / 2
		btn.connect("mouse_entered", self, "_on_btn_hover", [btn_name])
		btn.connect("mouse_exited", self, "_on_btn_exit")
		btn.connect("pressed", self, "_on_btn_pressed", [btn_name])
	padlock.rect_pivot_offset = padlock.rect_size / 2
	$HoverLabel.visible = false
	$HintButton.connect("pressed", self, "_on_HintButton_pressed")
	$HintButton.connect("mouse_entered", self, "_on_Hint_hover")
	$HintButton.connect("mouse_exited", self, "_on_btn_exit")
	padlock.hide()
	if GameData.owned_recipes.size() > 0:
		if GameData.has_played_unlock_anim == false:
			padlock.show()
			padlock.modulate.a = 1.0
			
			var tw_lock = create_tween()
			tw_lock.tween_interval(0.5)
			tw_lock.tween_property(padlock, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw_lock.parallel().tween_property(padlock, "rect_scale", Vector2(1.5, 1.5), 1.0)
			
			yield(tw_lock, "finished")
			
			padlock.hide()
			GameData.has_played_unlock_anim = true
			
		else:
			pass 
			
	else:
		padlock.show()
		padlock.modulate.a = 1.0
		padlock.rect_scale = Vector2(1, 1)
	yield(get_tree().create_timer(1.0), "timeout")
	$CanvasLayer.hide()
func _on_btn_hover(btn_name):
	var btn = get_node(btn_name)
	btn.rect_scale = Vector2(1.1, 1.1)
	$HoverLabel.text = locations[btn_name]["label"]
	$HoverLabel.visible = true

func _on_btn_exit():
	for btn_name in locations.keys():
		get_node(btn_name).rect_scale = Vector2(1,1)
	$HintButton.rect_scale = Vector2(1,1)
	$HoverLabel.visible = false

func _on_btn_pressed(btn_name):
	if btn_name == "KitchenButton":
		if padlock.visible:
			print("Dapur terkunci! (Ada gembok)")
			animasi_gembok_terkunci()
			return
	var scene_path = locations[btn_name]["scene"]
	get_tree().change_scene(scene_path)
	$CanvasLayer.show()
	var fade = $CanvasLayer/ColorRect
	create_tween().tween_property(fade, "modulate:a", 1.0, 0.5)
	yield(get_tree().create_timer(0.5), "timeout")

func animasi_gembok_terkunci():
	padlock.rect_pivot_offset = padlock.rect_size / 2
	
	var tw = create_tween()
	tw.tween_property(padlock, "rect_rotation", 15.0, 0.05)
	tw.tween_property(padlock, "rect_rotation", -15.0, 0.05)
	tw.tween_property(padlock, "rect_rotation", 10.0, 0.05)
	tw.tween_property(padlock, "rect_rotation", -10.0, 0.05)
	tw.tween_property(padlock, "rect_rotation", 0.0, 0.05)
	
func _process(delta):
	if $HoverLabel.visible and $HoverLabel.text != "Tutorial Game":
		$HoverLabel.rect_global_position = get_viewport().get_mouse_position() + Vector2(0, -30)
func _on_HintButton_pressed():
	get_node("TutorialPopup").popup_centered()

func _on_Hint_hover():
	$HintButton.rect_scale = Vector2(1.1, 1.1)
	$HoverLabel.text = "Tutorial Game"
	$HoverLabel.visible = true
	
	yield(get_tree(), "idle_frame")
	var btn_pos = $HintButton.rect_global_position
	var btn_size = $HintButton.rect_size * $HintButton.rect_scale
	
	var pos_x = btn_pos.x + (btn_size.x / 2) - ($HoverLabel.rect_size.x / 2)
	var pos_y = btn_pos.y + btn_size.y + 10
	
	$HoverLabel.rect_global_position = Vector2(pos_x, pos_y)
