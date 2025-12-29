extends Control
var hover_text = {
	"AboutButton": "Tentang Game",
	"PlayButton": "Mulai Bermain",
	"ExitButton": "Keluar dari Game",
	"BackButton": "Kembali ke Menu"
}
onready var about_popup = $AboutText
onready var about_back_btn = $AboutText/BackButton
onready var hover_label = $HoverLabel
func _ready():
	about_popup.hide()
	about_back_btn.connect("pressed", self, "_on_about_back_pressed")
	about_back_btn.connect("mouse_entered", self, "_on_button_hover", [about_back_btn])
	about_back_btn.connect("mouse_exited", self, "_on_button_leave")
	$M/C/HB/AboutButton.connect("pressed", self, "_on_about_pressed")
	$M/C/HB/PlayButton.connect("pressed", self, "_on_play_pressed")
	$M/C/HB/ExitButton.connect("pressed", self, "_on_exit_pressed")
	connect_hover_signals()
	animate_title_up()
	FX.play_slow()
	
func connect_hover_signals():
	var hb = $M/C/HB
	for i in range(hb.get_child_count()):
		var btn = hb.get_child(i)
		btn.connect("mouse_entered", self, "_on_button_hover", [btn])
		btn.connect("mouse_exited", self, "_on_button_leave")
		
func _on_button_hover(btn):
	if about_popup.visible and btn != about_back_btn:
		return
	if not about_popup.visible and btn == about_back_btn:
		return
	var name = btn.name
	
	if hover_text.has(name):
		$HoverLabel.text = hover_text[name]
		
		var btn_pos = btn.get_global_position()
		var btn_size = btn.rect_size
		
		var label_pos = Vector2(
			btn_pos.x + (btn_size.x - hover_label.rect_size.x)/2,
			btn_pos.y - 10
		)
		
		$HoverLabel.rect_global_position = label_pos
		$HoverLabel.visible = true
		$HoverLabel.raise()

func _on_button_leave():
	$HoverLabel.visible = false
	
func animate_title_up():
	var tween = $Tween
	var start_pos = $Title.rect_position
	var end_pos = start_pos + Vector2(0, +462)
	
	tween.interpolate_property(
		$Title,
		"rect_position",
		start_pos,
		end_pos,
		1.0,               
		Tween.TRANS_BOUNCE,
		Tween.EASE_OUT
	)
	tween.start()
	
func _on_exit_pressed():
	get_tree().quit()

func _on_play_pressed():
	get_tree().change_scene("res://Scene/Map.tscn")
	
func _on_about_pressed():
	about_popup.show()
	about_popup.modulate.a = 0.0 
	about_popup.rect_scale = Vector2(0.9, 0.9)
	about_popup.rect_pivot_offset = about_popup.rect_size / 2 
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(about_popup, "modulate:a", 1.0, 0.3)
	tw.tween_property(about_popup, "rect_scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_about_back_pressed():
	var tw = create_tween()
	tw.tween_property(about_popup, "modulate:a", 0.0, 0.2)
	yield(tw, "finished")
	about_popup.hide()
	hover_label.visible = false
