extends Control

onready var hover_label = $HoverLabel
onready var ui_blocker = $UIBlocker

var health = 3
var total_questions = 0
var current_question = 0

func _ready():
	$BackToMenu.show()
	$BookUI.hide()
	$QuizUI.hide()
	$BackToMenu.connect("pressed", self, "Menupressed")
	$ProgressBar/A2.connect("pressed", self, "next")
	$ProgressBar/A3.connect("pressed", self, "back")
	$BookUI/BackButton.connect("pressed", self, "_on_book_back_pressed")

	$BookUI/DifficultyMenu/EasyButton.connect("pressed", self, "_on_difficulty_selected", ["Easy"])
	$BookUI/DifficultyMenu/MediumButton.connect("pressed", self, "_on_difficulty_selected", ["Medium"])
	$BookUI/DifficultyMenu/HardButton.connect("pressed", self, "_on_difficulty_selected", ["Hard"])

	hover_label.hide()
	var mapel = ["Biologi", "Fisika", "Kimia", "Matematika"]
	for i in range($ShelfButton.get_child_count()):
		var shelf = $ShelfButton.get_child(i)
		shelf.connect("mouse_entered", self, "_on_shelf_entered", [shelf, mapel[i]])
		shelf.connect("mouse_exited", self, "_on_shelf_exited")
		shelf.connect("pressed", self, "_on_shelf_pressed", [shelf, mapel[i]])

func _on_shelf_pressed(shelf, mapel):
	$BackToMenu.hide()
	ui_blocker.show()
	$BackToMenu.disabled = true
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

	var buttons = [
		menu.get_node("EasyButton"),
		menu.get_node("MediumButton"),
		menu.get_node("HardButton")
	]

	for i in range(buttons.size()):
		var btn = buttons[i]
		btn.modulate.a = 0
		btn.rect_position.y += 40

	for i in range(buttons.size()):
		var btn = buttons[i]
		var tween = create_tween()
		tween.tween_property(btn, "modulate:a", 1, 0.4).set_delay(i * 0.1)
		tween.tween_property(btn, "rect_position:y", btn.rect_position.y - 40, 0.4).set_delay(i * 0.1)

func _on_difficulty_selected(level):
	match level:
		"Easy":
			total_questions = 3
		"Medium":
			total_questions = 5
		"Hard":
			total_questions = 7

	$ProgressBar.max_value = total_questions
	$ProgressBar.value = 0
	current_question = 0

	print("Level:", level, " | Jumlah Soal:", total_questions)

	$BookUI.hide()
	show_quiz_ui_animation()
	$ProgressBar.show()
	$ProgressCat1.show()
	$ProgressCat1.play("default")
	$ProgressCat1.speed_scale = 1.0
	$QuizUI.show()
	$QuizUI/Hearts.show()

func next():
	$Book_animated.frame = 0
	$Book_animated.play("next")

	if current_question < total_questions:
		current_question += 1
		$ProgressBar.value = current_question
		update_cat_position()

	if current_question >= total_questions:
		$ProgressCat1.speed_scale = 2.0
		yield(get_tree().create_timer(1.5), "timeout")
		$ProgressBar.hide()
		$ProgressCat1.hide()
		$QuizUI/Hearts.hide()

		var light = $QuizUI/Light
		light.show()
		light.modulate.a = 0
		light.scale = Vector2(0.5, 0.5)

		var tween_in = create_tween()
		tween_in.tween_property(light, "modulate:a", 1, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween_in.tween_property(light, "scale", Vector2(3.665, 2.236), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		yield(tween_in, "finished")

		yield(get_tree().create_timer(1.2), "timeout")

		var tween_out = create_tween()
		tween_out.tween_property(light, "modulate:a", 0, 1).set_trans(Tween.TRANS_LINEAR)
		yield(tween_out, "finished")

		$QuizUI.hide()

		$Book_animated.play("close")
		yield($Book_animated, "animation_finished")
		$Book_animated.hide()

		$ShelfButton.modulate.a = 1
		$Background.modulate.a = 1
		$BackToMenu.show()
		$BackToMenu.disabled = false
		ui_blocker.hide()
		$ProgressBar.value=0
		$ProgressCat1.position.x = 138

func back():
	print("Hello")
	if health > 0:
		health -= 1
		update_health_display()
	if health == 0:
		$BookUI.hide()
		$Book_animated.hide()
		$ProgressBar.hide()
		$QuizUI/Hearts.hide()
		$ProgressCat1.hide()
		$QuizUI/AnimatedSprite.show()
		$QuizUI/AnimatedSprite.frame = 0
	
		$QuizUI/AnimatedSprite.play("idle")
		yield($QuizUI/AnimatedSprite, "animation_finished")
		$QuizUI/AnimatedSprite.hide()
		$QuizUI.hide()
		reset_state()

		$ShelfButton.modulate.a = 1
		$Background.modulate.a = 1
		$BackToMenu.show()
		$BackToMenu.disabled = false
		ui_blocker.hide()
		$ProgressBar.value=0
		$ProgressCat1.position.x = 138

func _on_shelf_entered(shelf, mapel):
	if not ui_blocker.visible:
		show_hover(mapel, shelf)

func _on_shelf_exited():
	hover_label.hide()

func show_hover(text, shelf_node):
	hover_label.text = text
	hover_label.show()
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
			hearts[i].modulate = Color(0.6, 0.6, 0.6)
			create_tween().tween_property(hearts[i], "rect_position:y", -20, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
func _on_book_back_pressed():
	$BookUI.hide()
	$QuizUI.hide()
	$ProgressBar.hide()
	$ProgressCat1.hide()
	hover_label.hide()

	$ShelfButton.modulate.a = 1.0
	$Background.modulate.a = 1.0
	$BackToMenu.show()
	$BackToMenu.disabled = false

	if $Book_animated.is_playing():
		$Book_animated.stop()
	$Book_animated.frame=0
	$Book_animated.play("close")


	yield($Book_animated, "animation_finished")

	$Book_animated.hide()
	ui_blocker.hide()

func Menupressed():
	get_tree().change_scene("res://Scene/Map.tscn")
func reset_state():
	health = 3
	current_question = 0
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

