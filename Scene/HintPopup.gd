extends PopupPanel

var pages = [
	preload("res://asset/hint/hint 1.png"),
	preload("res://asset/hint/hint 2.png"),
	preload("res://asset/hint/hint 3.png")
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

func _on_PrevButton_pressed():
	if current_page > 0:
		current_page -= 1
		update_page()

func _on_NextButton_pressed():
	if current_page < pages.size() - 1:
		current_page += 1
		update_page()

