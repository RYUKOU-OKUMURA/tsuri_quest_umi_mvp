extends Node

const JuicerScript = preload("res://src/autoload/juicer.gd")

var _failed := false
var _juicer: Node


func _ready() -> void:
	get_tree().paused = false
	_juicer = JuicerScript.new()
	add_child(_juicer)

	_verify_zero_is_no_op()
	_verify_owned_pause_is_released()
	_verify_preexisting_pause_is_preserved()
	_verify_overlapping_stops_keep_longest_duration()
	_verify_overlapping_stops_preserve_preexisting_pause()

	get_tree().paused = false
	_juicer.queue_free()
	if _failed:
		return
	print("juicer_smoke: ok")
	get_tree().quit(0)


func _verify_zero_is_no_op() -> void:
	_reset_juicer_state()
	_juicer.hit_stop(0.0)
	_expect(not get_tree().paused, "zero-second hit stop must not pause the tree")
	_expect(is_zero_approx(_juicer._freeze), "zero-second hit stop must not start a timer")
	_expect(not _juicer._owns_tree_pause, "zero-second hit stop must not claim pause ownership")

	_juicer.hit_stop(-1.0)
	_expect(not get_tree().paused, "negative hit stop must be a complete no-op")


func _verify_owned_pause_is_released() -> void:
	_reset_juicer_state()
	_juicer.hit_stop(0.05)
	_expect(get_tree().paused, "positive hit stop must pause an unpaused tree")
	_expect(_juicer._owns_tree_pause, "hit stop must own a pause it started")

	_juicer._process(0.02)
	_expect(get_tree().paused, "hit stop must keep the tree paused before expiry")
	_juicer._process(0.04)
	_expect(not get_tree().paused, "hit stop must release a pause it started after expiry")
	_expect(not _juicer._owns_tree_pause, "expired hit stop must release pause ownership")


func _verify_preexisting_pause_is_preserved() -> void:
	_reset_juicer_state()
	get_tree().paused = true
	_juicer.hit_stop(0.05)
	_expect(not _juicer._owns_tree_pause, "hit stop must not own a preexisting pause")

	_juicer._process(0.06)
	_expect(get_tree().paused, "hit stop expiry must preserve a preexisting pause")
	get_tree().paused = false


func _verify_overlapping_stops_keep_longest_duration() -> void:
	_reset_juicer_state()
	_juicer.hit_stop(0.08)
	_juicer._process(0.02)
	var remaining_before_shorter_call: float = _juicer._freeze
	_juicer.hit_stop(0.01)
	_expect(
		is_equal_approx(_juicer._freeze, remaining_before_shorter_call),
		"a shorter overlapping stop must not shorten the remaining duration"
	)
	_expect(_juicer._owns_tree_pause, "overlapping stops must preserve original pause ownership")

	_juicer.hit_stop(0.10)
	_expect(is_equal_approx(_juicer._freeze, 0.10), "a longer overlapping stop must extend the duration")
	_juicer._process(0.09)
	_expect(get_tree().paused, "extended hit stop must remain paused until the longest duration expires")
	_juicer._process(0.02)
	_expect(not get_tree().paused, "extended owned hit stop must release pause after expiry")


func _verify_overlapping_stops_preserve_preexisting_pause() -> void:
	_reset_juicer_state()
	get_tree().paused = true
	_juicer.hit_stop(0.04)
	_juicer.hit_stop(0.09)
	_expect(not _juicer._owns_tree_pause, "overlap must not claim ownership of a preexisting pause")
	_juicer._process(0.10)
	_expect(get_tree().paused, "overlap expiry must preserve a preexisting pause")
	get_tree().paused = false


func _reset_juicer_state() -> void:
	get_tree().paused = false
	_juicer._freeze = 0.0
	_juicer._owns_tree_pause = false


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	get_tree().paused = false
	push_error(message)
	get_tree().quit(1)
