extends Control
var hover_text = {	"AboutButton": "Tentang Game",
	"PlayButton": "Mulai Bermain",
	"ExitButton": "Keluar dari Game"
}

func _ready():
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
	var name = btn.name
	
	if hover_text.has(name):
		$HoverLabel.text = hover_text[name]
		
		# POSISI LABEL (di atas tombol)
		var btn_pos = btn.get_global_position() # Vector2
		var btn_size = btn.rect_size            # ukuran tombol
		
		var label_pos = Vector2(
			btn_pos.x + (btn_size.x - $HoverLabel.rect_size.x)/2,  # center X
			btn_pos.y - 20                                          # 20px di atas tombol
		)
		
		$HoverLabel.rect_global_position = label_pos
		$HoverLabel.visible = true

func _on_button_leave():
	$HoverLabel.visible = false
	
func animate_title_up():
	var tween = $Tween
	var start_pos = $Title.position
	var end_pos = start_pos + Vector2(0, +462)  # naik 250px (sesuai kebutuhan)
	
	tween.interpolate_property(
		$Title,
		"position",
		start_pos,
		end_pos,
		1.0,                # durasi animasi
		Tween.TRANS_BOUNCE,   # transisi halus
		Tween.EASE_OUT
	)
	tween.start()
	
func _on_exit_pressed():
#	FX.play_tombol()
	get_tree().quit()

func _on_play_pressed():
##	FX.play_tombol()
#	print("Play ditekan, masuk ke Map")
	get_tree().change_scene("res://Scene/Map.tscn")

func _on_about_pressed():
#	print("About ditekan")
	var popup = AcceptDialog.new()
	popup.dialog_text = "Game ini dibuat oleh Yahya dan Naufal"
	add_child(popup)
	popup.popup_centered()

