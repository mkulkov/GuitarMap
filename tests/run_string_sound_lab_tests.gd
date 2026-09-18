extends SceneTree

const StringSoundLabScript = preload("res://scripts/ui/string_sound_lab.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = load("res://scenes/labs/string_sound_lab.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.preset_dictionary().schema == "guitarmap.string_sound_lab.v1")
	assert(scene.preset_dictionary().parameters.size() == 6)
	scene._set_parameter(0.83, "sustain")
	assert(is_equal_approx(float(scene.parameters.sustain), 0.83))
	# The headless Dummy audio driver retains AudioStreamPlaybackWAV until engine
	# shutdown after play(), producing a false ObjectDB leak. Validate the exact
	# stream that play_note() uses without starting the unavailable audio device.
	var generated_stream: AudioStreamWAV = scene._stream_for(62)
	assert(generated_stream.data.size() == int(StringSoundLabScript.MIX_RATE * StringSoundLabScript.DURATION_SECONDS) * 2)
	assert(generated_stream.mix_rate == StringSoundLabScript.MIX_RATE)
	assert(not generated_stream.stereo and generated_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED)
	generated_stream = null
	scene.queue_free()
	await process_frame
	await create_timer(0.12).timeout
	print("String sound lab tests passed: five-note preview, parameter hand-off preset and generated PCM.")
	quit()
