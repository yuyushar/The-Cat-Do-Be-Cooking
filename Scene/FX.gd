extends Node

func play_slow():
	$fast_music.stop()
	if $slow_music.playing :
		return
	$slow_music.play()
func play_fast():
	$slow_music.stop()
	$fast_music.play()
