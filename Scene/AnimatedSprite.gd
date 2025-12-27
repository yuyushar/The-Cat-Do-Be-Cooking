extends AnimatedSprite

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
