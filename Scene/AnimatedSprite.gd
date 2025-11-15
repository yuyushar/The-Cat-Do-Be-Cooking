extends AnimatedSprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	play("idle")
	randomize()
	_random_animation()

func _random_animation():
	var value = randf()

	if value <= 0.7:
		play("idle")
	else:
		play("blink")
	var anim_length = frames.get_frame_count(animation) / frames.get_animation_speed(animation)
	yield(get_tree().create_timer(anim_length), "timeout")

	_random_animation()



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
