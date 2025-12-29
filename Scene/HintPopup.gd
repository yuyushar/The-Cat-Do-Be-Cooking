extends PopupPanel

var pages = [
	preload("res://asset/hint/1.png"),
	preload("res://asset/hint/2.png"),
	preload("res://asset/hint/3.png"),
	preload("res://asset/hint/4.png"),
	preload("res://asset/hint/5.png"),
	preload("res://asset/hint/6.png"),
	preload("res://asset/hint/7.png"),
	preload("res://asset/hint/8.png"),
	preload("res://asset/hint/9.png"),
	preload("res://asset/hint/10.png"),
	preload("res://asset/hint/11.png"),
	preload("res://asset/hint/12.png")
]

var current_page = 0

onready var page_texture = $PanelContainer/VBoxContainer/PageTexture
onready var prev_btn = $PanelContainer/VBoxContainer/ButtonBar/PrevButton
onready var next_btn = $PanelContainer/VBoxContainer/ButtonBar/NextButton

func _ready():
	update_page()
	prev_btn.connect("pressed", self, "_on_prev")
	next_btn.connect("pressed", self, "_on_next")
	$PanelContainer/VBoxContainer/ButtonBar/ExitButton.connect("pressed", self, "hide")

func update_page():
	page_texture.texture = pages[current_page]

	prev_btn.disabled = current_page == 0
	next_btn.disabled = current_page == pages.size() - 1

func _on_prev():
	if current_page > 0:
		current_page -= 1
		update_page()

func _on_next():
	if current_page < pages.size() - 1:
		current_page += 1
		update_page()

