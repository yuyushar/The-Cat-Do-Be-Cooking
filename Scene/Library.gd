extends Control

onready var hover_label = $HoverLabel
onready var ui_blocker = $UIBlocker
onready var result_popup = $QuizUI/ResultPopup
onready var failed_sprite = $QuizUI/Failed
onready var bad_end_node = $QuizUI/bad_end
onready var bad_end2_node = $QuizUI/bad_end2
var health = 3
var total_questions = 0
var current_question_index = 0
var current_questions_list = []
var current_mapel = ""
var current_difficulty = ""
var origin_bar_y = 0
var origin_cat_x = 0
var origin_question_x = 0
var origin_answers_x = 0
var origin_explanation_y = 0
func _ready():
	$BackToMap.show()
	$BookUI.hide()
	$QuizUI.hide()
	result_popup.hide()
	if failed_sprite: failed_sprite.hide()
	bad_end_node.hide()
	$BackToMap.connect("pressed", self, "Menupressed")
	$BookUI/BackButton.connect("pressed", self, "_on_book_back_pressed")
	$BookUI/DifficultyMenu/EasyButton.connect("pressed", self, "_on_difficulty_selected", ["Easy"])
	$BookUI/DifficultyMenu/MediumButton.connect("pressed", self, "_on_difficulty_selected", ["Medium"])
	$BookUI/DifficultyMenu/HardButton.connect("pressed", self, "_on_difficulty_selected", ["Hard"])
	var answer_buttons = $QuizUI.get_node("Answer Button")
	answer_buttons.get_node("A").connect("pressed", self, "_on_answer_pressed", ["A"])
	answer_buttons.get_node("B").connect("pressed", self, "_on_answer_pressed", ["B"])
	answer_buttons.get_node("C").connect("pressed", self, "_on_answer_pressed", ["C"])
	answer_buttons.get_node("D").connect("pressed", self, "_on_answer_pressed", ["D"])
	bad_end_node.get_node("ReturnButton").connect("pressed", self, "_on_book_back_pressed")
	bad_end_node.get_node("RetryButton").connect("pressed", self, "_retry_quiz")

	if result_popup.has_node("KitchenButton"):
		var btn_kitchen = result_popup.get_node("KitchenButton")
		btn_kitchen.connect("pressed", self, "_goto_kitchen")
		btn_kitchen.connect("mouse_entered", self, "_on_result_btn_hover", [btn_kitchen, "Kedapur"])
		btn_kitchen.connect("mouse_exited", self, "_on_result_btn_exit")
	if result_popup.has_node("BackLibraryButton"):
		var btn_back = result_popup.get_node("BackLibraryButton")
		btn_back.connect("pressed", self, "_on_book_back_pressed")
		btn_back.connect("mouse_entered", self, "_on_result_btn_hover", [btn_back, "Kembali"])
		btn_back.connect("mouse_exited", self, "_on_result_btn_exit")
		
	hover_label.hide()
	_add_hover($BackToMap, "Kembali ke Menu Utama")
	_add_hover($BookUI/BackButton, "Tutup Buku")
	_add_hover(bad_end_node.get_node("ReturnButton"), "Menyerah / Kembali")
	_add_hover(bad_end_node.get_node("RetryButton"), "Coba Lagi")
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
func _add_hover(btn_node, text):
	if not btn_node.is_connected("mouse_entered", self, "_on_result_btn_hover"):
		btn_node.connect("mouse_entered", self, "_on_result_btn_hover", [btn_node, text])
		btn_node.connect("mouse_exited", self, "_on_result_btn_exit")
func _on_shelf_pressed(shelf, mapel):
	current_mapel = mapel
	$BackToMap.hide()
	ui_blocker.show()
	$BackToMap.disabled = true
	
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
	
	var unlocked_level = GameData.difficulty_progress[current_mapel]
	
	menu.get_node("EasyButton").disabled = false
	menu.get_node("MediumButton").disabled = (unlocked_level < 1)
	menu.get_node("HardButton").disabled = (unlocked_level < 2)
	
	menu.get_node("MediumButton").modulate = Color(1,1,1) if unlocked_level >= 1 else Color(0.5,0.5,0.5)
	menu.get_node("HardButton").modulate = Color(1,1,1) if unlocked_level >= 2 else Color(0.5,0.5,0.5)

	var buttons = [menu.get_node("EasyButton"), menu.get_node("MediumButton"), menu.get_node("HardButton")]
	for i in range(buttons.size()):
		var btn = buttons[i]
		btn.modulate.a = 0
		btn.rect_position.y += 40
		var tween = create_tween()
		tween.tween_property(btn, "modulate:a", 1, 0.4).set_delay(i * 0.1)
		tween.tween_property(btn, "rect_position:y", btn.rect_position.y - 40, 0.4).set_delay(i * 0.1)

func _on_difficulty_selected(level):
	current_difficulty = level
	
	current_questions_list = $QuizManager.get_questions(current_mapel, level)

	if current_questions_list.size() == 0:
		print("Soal kosong!")
		return

	match level:
		"Easy": total_questions = 3
		"Medium": total_questions = 5
		"Hard": total_questions = 7
	
	if current_questions_list.size() > total_questions:
		current_questions_list.resize(total_questions)

	$ProgressBar.max_value = total_questions
	$ProgressBar.value = 0
	
	$ProgressCat1.position.x = 138
	current_question_index = 0
	health = 3
	
	$BookUI.hide()
	var hearts = $QuizUI/Hearts.get_children()
	for h in hearts:
		if h.get_node_or_null("Tween"): 
			h.get_node("Tween").stop_all() 
		
		h.modulate = Color(1, 1, 1)
		h.rect_position.y = 0
	show_quiz_ui_animation()
	$ProgressBar.show()
	$ProgressCat1.show()
	$ProgressCat1.play("default")
	$ProgressCat1.speed_scale = 1.0
	$QuizUI.show()
	$QuizUI/Light.hide()
	result_popup.hide()
	bad_end_node.hide()
	$QuizUI/QuestionLabel.show()         
	$QuizUI.get_node("Answer Button").show()
	$QuizUI/Hearts.show()
	$QuizUI/ExplanationLabel.hide()
	var btns = $QuizUI.get_node("Answer Button")
	for child in btns.get_children():
		child.disabled = false  
		child.pressed = false
	load_current_question_to_ui()
	$QuizUI/QuestionLabel.modulate.a = 0
	$QuizUI.get_node("Answer Button").modulate.a = 0
	
	animate_ui_in()

func load_current_question_to_ui():
	var data = current_questions_list[current_question_index]
	
	$QuizUI/QuestionLabel.text = data["question"]
	
	var btn_node = $QuizUI.get_node("Answer Button")
	var options = data["options"]
	btn_node.get_node("A").text = str(options[0])
	btn_node.get_node("B").text = str(options[1])
	btn_node.get_node("C").text = str(options[2])
	btn_node.get_node("D").text = str(options[3])
func _on_answer_pressed(pilihan_user):
	var data = current_questions_list[current_question_index]
	var jawaban_benar = str(data["answer"])
	var btns = $QuizUI.get_node("Answer Button")
	for child in btns.get_children():
		child.disabled = true
		
	if pilihan_user.to_upper() == jawaban_benar.to_upper():
		print("Benar!")
		show_explanation_sequence(data)
	else:
		print("Salah!")
		wrong_answer()
		if health > 0:
			for child in btns.get_children():
				child.disabled = false
func show_explanation_sequence(data):
	var btns = $QuizUI.get_node("Answer Button")
	var expl_text = "Penjelasan: " + str(data.get("Explanation", "Tidak ada penjelasan."))
	$QuizUI/ExplanationLabel.text = expl_text
	$QuizUI/ExplanationLabel.show()
	$QuizUI/ExplanationLabel.modulate.a = 0
	var tween = create_tween()
	tween.tween_property($QuizUI/ExplanationLabel, "modulate:a", 1, 0.5)
	yield(get_tree().create_timer(3.0), "timeout")
	proceed_to_next_step()
func proceed_to_next_step():
	animate_ui_out()
	yield(get_tree().create_timer(0.5), "timeout")
	$QuizUI/ExplanationLabel.hide()
	$Book_animated.frame = 0
	$Book_animated.play("next")
	yield($Book_animated, "animation_finished")
	current_question_index += 1
	$ProgressBar.value = current_question_index
	update_cat_position()
	if current_question_index < total_questions:
		load_current_question_to_ui()
		var btns = $QuizUI.get_node("Answer Button")
		for child in btns.get_children():
			child.disabled = false
		animate_ui_in()
		
	else:
		quiz_finished_win()
func _on_result_btn_hover(btn_node, text):
	hover_label.text = text
	hover_label.rect_size = Vector2(0, 0) 
	hover_label.show()
	yield(get_tree(), "idle_frame") 
	if is_instance_valid(btn_node):
		var btn_global_pos = btn_node.rect_global_position
		var total_scale = btn_node.get_global_transform().get_scale()
		var true_width = btn_node.rect_size.x * total_scale.x
		var label_size = hover_label.rect_size
		var pos_x = btn_global_pos.x + (true_width / 2) - (label_size.x / 2)
		var pos_y = btn_global_pos.y - label_size.y - 15
		hover_label.rect_global_position = Vector2(pos_x, pos_y)
		hover_label.raise()

func _on_result_btn_exit():
	hover_label.hide()
	
func next_question():
	$Book_animated.frame = 0
	$Book_animated.play("next")

	current_question_index += 1
	$ProgressBar.value = current_question_index
	update_cat_position()

	if current_question_index < total_questions:
		load_current_question_to_ui()
	else:
		quiz_finished_win()
func animate_ui_in():
	var q_label = $QuizUI/QuestionLabel
	var btn_group = $QuizUI.get_node("Answer Button")
	
	q_label.rect_position.x = origin_question_x + 50
	btn_group.rect_position.x = origin_answers_x + 50
	
	q_label.modulate.a = 0
	btn_group.modulate.a = 0
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(q_label, "rect_position:x", origin_question_x, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(q_label, "modulate:a", 1, 0.5)
	
	tween.tween_property(btn_group, "rect_position:x", origin_answers_x, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.1) # Delay dikit biar gantian
	tween.tween_property(btn_group, "modulate:a", 1, 0.5).set_delay(0.1)

func animate_ui_out():
	var q_label = $QuizUI/QuestionLabel
	var btn_group = $QuizUI.get_node("Answer Button")
	var expl_label = $QuizUI/ExplanationLabel
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(q_label, "rect_position:x", origin_question_x - 50, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(q_label, "modulate:a", 0, 0.4)
	tween.tween_property(btn_group, "rect_position:x", origin_answers_x - 50, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(btn_group, "modulate:a", 0, 0.4)
	tween.tween_property(expl_label, "modulate:a", 0, 0.4)

func wrong_answer():
	if health > 0:
		health -= 1
		update_health_display()
	
	if health <= 0:
		quiz_finished_lose()

func quiz_finished_win():
	$ProgressCat1.speed_scale = 2.0
	yield(get_tree().create_timer(1.0), "timeout")
	update_result_popup_content()
	$ProgressBar.hide()
	$ProgressCat1.hide()
	$QuizUI/Hearts.hide()
	$QuizUI/QuestionLabel.hide()
	$QuizUI.get_node("Answer Button").hide()

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
	
	var data = GameData.get_recipe_data(current_mapel, current_difficulty)
	var resep_baru = data["name"]
	if not resep_baru in GameData.owned_recipes:
		GameData.owned_recipes.append(resep_baru)
		print("BERHASIL: Resep " + resep_baru + " ditambahkan ke GameData!")
	GameData.unlock_next_difficulty(current_mapel, current_difficulty)	

	$ShelfButton.modulate.a = 0.3
	$Background.modulate.a = 0.3
	$BackToMap.hide()
	$BackToMap.disabled = false
	$ProgressBar.value=0
	$ProgressCat1.position.x = 138
	
func update_result_popup_content():
	var data = GameData.get_recipe_data(current_mapel, current_difficulty)
	
	if result_popup.has_node("FoodIcon"):
		var nama_file = data["name"].to_lower().replace(" ", "_") + ".png"
		var path = "res://asset/food/" + nama_file
		var loaded_tex = load(path)
		if loaded_tex:
			result_popup.get_node("FoodIcon").texture = loaded_tex
		else:
			print("Gambar makanan GAGAL di-load: ", path)
	if result_popup.has_node("FoodNameLabel"):
		result_popup.get_node("FoodNameLabel").text = data["name"]
	if result_popup.has_node("IngredientsLabel"): 
		var raw_text = data["ing"]
		var formatted_text = raw_text.replace(",", " +")
		result_popup.get_node("IngredientsLabel").text = formatted_text
	if result_popup.has_node("IngredientsContainer"):
		var container = result_popup.get_node("IngredientsContainer")
		
		for child in container.get_children():
			child.queue_free()
		var list_bahan = data["ing"].split(",")
		for nama_bahan_mentah in list_bahan:
			var nama_bersih = nama_bahan_mentah.strip_edges()
			var nama_file = str(nama_bersih).to_lower()
			var path = "res://asset/ingridients/" + nama_file + ".png"
			var tex_bahan = load(path)
			if tex_bahan:
				var texture_rect = TextureRect.new()
				texture_rect.texture = load(path)
				texture_rect.expand = true
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				texture_rect.rect_min_size = Vector2(120,120)
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
	if failed_sprite: failed_sprite.hide()
	
	bad_end_node.hide()
	bad_end2_node.show()
	if failed_sprite: 
		failed_sprite.show()
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
		bad_end_node.frame = 0
		bad_end_node.play("idle")
		yield(bad_end_node, "animation_finished")
		
		if not bad_end_node.visible: 
			break
		bad_end_node.play("blink")
		yield(bad_end_node, "animation_finished")
		
func _retry_quiz():
	if failed_sprite: failed_sprite.hide() 
	bad_end_node.hide()
	bad_end_node.stop()
	$Book_animated.show()
	$Book_animated.frame=0
	$Book_animated.play("open")
	yield($Book_animated, "animation_finished")
	_on_difficulty_selected(current_difficulty)

func _goto_kitchen():
	get_tree().change_scene("res://Scene/Kitchen.tscn")
	
func _on_book_back_pressed():
	hover_label.hide()
	$BookUI.hide()
	$QuizUI.hide()
	$ProgressBar.hide()
	$ProgressCat1.hide()
	result_popup.hide()
	bad_end_node.hide()
	hover_label.hide()
	if failed_sprite: failed_sprite.hide() 
	$QuizUI/QuestionLabel.show()
	$QuizUI.get_node("Answer Button").show()

	if $Book_animated.visible:
		if $Book_animated.is_playing(): 
			$Book_animated.stop()
		
		$Book_animated.frame = 0
		$Book_animated.play("close")
		yield($Book_animated, "animation_finished")
		
		$Book_animated.hide()
	else:
		$Book_animated.stop()
	$ShelfButton.modulate.a = 1.0
	$Background.modulate.a = 1.0
	$BackToMap.show()
	$BackToMap.disabled = false
	ui_blocker.hide()

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
	hover_label.rect_size = Vector2(0, 0)
	hover_label.show()
	yield(get_tree(), "idle_frame")
	if is_instance_valid(shelf_node):
		var global_pos = shelf_node.rect_global_position
		var total_scale = shelf_node.get_global_transform().get_scale()
		var true_width = shelf_node.rect_size.x * total_scale.x
		var true_height = shelf_node.rect_size.y * total_scale.y
		var pos_x = global_pos.x + (true_width / 2) - (hover_label.rect_size.x / 2)
		var pos_y = global_pos.y + true_height + 5
		
		hover_label.rect_global_position = Vector2(pos_x, pos_y)
		hover_label.raise()

func show_quiz_ui_animation():
	var tween = get_tree().create_tween() 

	var bar = $ProgressBar
	var start_pos_bar = bar.rect_position.y + 100
	bar.rect_position.y = start_pos_bar
	bar.modulate.a = 0
	var t1 = $Tween.interpolate_property(bar, "rect_position:y", start_pos_bar, start_pos_bar - 100, 0.6, Tween.TRANS_BACK, Tween.EASE_OUT)
	var t2 = $Tween.interpolate_property(bar, "modulate:a", 0, 1, 0.6, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.interpolate_property($ProgressCat1, "modulate:a", 0, 1, 0.6, Tween.TRANS_LINEAR, Tween.EASE_OUT)

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
	if failed_sprite: failed_sprite.hide() 
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
