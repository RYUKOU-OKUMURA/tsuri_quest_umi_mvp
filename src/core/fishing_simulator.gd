class_name FishingSimulator
extends RefCounted

signal state_changed(new_state: int)
signal message_changed(message: String)
signal fight_finished(caught: bool, reason: String)

enum State {
	READY,
	CASTING,
	WAITING,
	APPROACH,
	BITE,
	FIGHT,
	CAUGHT,
	ESCAPED,
}

var state: int = State.READY
var fish_data: Dictionary = {}
var player_stats: Dictionary = {}

var tension: float = 0.32
var fish_stamina: float = 0.0
var fish_stamina_max: float = 1.0
var player_energy: float = 0.0
var player_energy_max: float = 1.0
var distance: float = 0.0
var initial_distance: float = 1.0
var depth: float = 0.0
var initial_depth: float = 0.0
var result_size_cm: float = 0.0

var reeling: bool = false
var giving_line: bool = false
var visual_position := Vector2(0.34, 0.55)
var visual_direction: float = 1.0
var action_name: String = "遊泳"
var action_message: String = "魚の気配を待とう。"

var _phase_timer: float = 0.0
var _bite_timer: float = 0.0
var _action_timer: float = 0.0
var _slack_timer: float = 0.0
var _visual_time: float = 0.0
var _action_multiplier: float = 0.65
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func prepare(target_fish: Dictionary, stats: Dictionary) -> void:
	fish_data = target_fish.duplicate(true)
	player_stats = stats.duplicate(true)
	state = State.READY
	tension = 0.32
	fish_stamina_max = maxf(1.0, float(fish_data.get("stamina", 40.0)))
	fish_stamina = fish_stamina_max
	player_energy_max = maxf(1.0, float(player_stats.get("max_energy", 100.0)))
	player_energy = player_energy_max
	initial_distance = maxf(10.0, float(fish_data.get("start_distance", 20.0)))
	distance = initial_distance
	initial_depth = maxf(2.0, float(fish_data.get("start_depth", 8.0)))
	depth = initial_depth
	result_size_cm = 0.0
	reeling = false
	giving_line = false
	visual_position = Vector2(0.26, clampf(depth / 25.0, 0.30, 0.78))
	visual_direction = 1.0
	action_name = "準備"
	_set_message("狙う魚を決めて仕掛けを投げよう。")
	_set_state(State.READY)


func cast() -> bool:
	if state != State.READY:
		return false
	_phase_timer = 0.55
	action_name = "キャスト"
	_set_message("仕掛けを投入した……")
	_set_state(State.CASTING)
	return true


func hook() -> bool:
	if state != State.BITE:
		return false
	if _bite_timer <= 0.0:
		_escape("アワセが遅れ、魚に逃げられた。")
		return false
	tension = 0.38
	_action_timer = 0.2
	_slack_timer = 0.0
	action_name = "ヒット"
	_set_message("ヒット！ テンションを保って巻き上げよう！")
	_set_state(State.FIGHT)
	return true


func set_reeling(active: bool) -> void:
	reeling = active
	if active:
		giving_line = false


func set_giving_line(active: bool) -> void:
	giving_line = active
	if active:
		reeling = false


func tick(delta: float) -> void:
	_visual_time += delta
	match state:
		State.CASTING:
			_tick_casting(delta)
		State.WAITING:
			_tick_waiting(delta)
		State.APPROACH:
			_tick_approach(delta)
		State.BITE:
			_tick_bite(delta)
		State.FIGHT:
			_tick_fight(delta)


func safe_min() -> float:
	return float(player_stats.get("safe_min", 0.22))


func safe_max() -> float:
	return float(player_stats.get("safe_max", 0.72))


func line_break_limit() -> float:
	return float(player_stats.get("line_break_limit", 1.0))


func fish_stamina_ratio() -> float:
	return clampf(fish_stamina / fish_stamina_max, 0.0, 1.0)


func player_energy_ratio() -> float:
	return clampf(player_energy / player_energy_max, 0.0, 1.0)


func distance_ratio() -> float:
	return clampf(distance / initial_distance, 0.0, 1.5)


func bite_time_left() -> float:
	return maxf(0.0, _bite_timer)


func state_label() -> String:
	var labels: Array[String] = [
		"準備",
		"投入",
		"待機",
		"接近",
		"食いつき",
		"ファイト",
		"釣り上げ",
		"逃走",
	]
	if state < 0 or state >= labels.size():
		return "不明"
	return labels[state]


func _tick_casting(delta: float) -> void:
	_phase_timer -= delta
	visual_position = visual_position.lerp(Vector2(0.22, 0.52), minf(1.0, delta * 4.0))
	if _phase_timer <= 0.0:
		_phase_timer = _rng.randf_range(1.2, 2.8)
		action_name = "待機"
		_set_message("水中の様子を見ながら待とう……")
		_set_state(State.WAITING)


func _tick_waiting(delta: float) -> void:
	_phase_timer -= delta
	visual_position.x = 0.20 + sin(_visual_time * 0.8) * 0.025
	visual_position.y = clampf(initial_depth / 25.0 + sin(_visual_time * 0.5) * 0.02, 0.30, 0.80)
	if _phase_timer <= 0.0:
		_phase_timer = _rng.randf_range(1.0, 1.7)
		action_name = "接近"
		_set_message("魚がエサへ近づいている……")
		_set_state(State.APPROACH)


func _tick_approach(delta: float) -> void:
	_phase_timer -= delta
	var target := Vector2(0.61, clampf(initial_depth / 25.0, 0.32, 0.78))
	visual_position = visual_position.lerp(target, minf(1.0, delta * 1.4))
	visual_direction = 1.0
	if _phase_timer <= 0.0:
		_bite_timer = 1.05 + float(player_stats.get("bite_window_bonus", 0.0))
		action_name = "食いつき"
		_set_message("食いついた！ Eキーか［アワセる］を押せ！")
		_set_state(State.BITE)


func _tick_bite(delta: float) -> void:
	_bite_timer -= delta
	visual_position.x = 0.61 + sin(_visual_time * 12.0) * 0.012
	if _bite_timer <= 0.0:
		_escape("アワセのタイミングを逃した。")


func _tick_fight(delta: float) -> void:
	_action_timer -= delta
	if _action_timer <= 0.0:
		_choose_fish_action()

	var stamina_ratio := fish_stamina_ratio()
	var fatigue_factor := lerpf(0.42, 1.0, stamina_ratio)
	var fish_power := float(fish_data.get("power", 0.7)) * _action_multiplier * fatigue_factor
	var fish_speed := float(fish_data.get("speed", 1.0))
	var reel_power := float(player_stats.get("reel_power", 5.6))
	var energy_regen := float(player_stats.get("energy_regen", 14.0))
	var energy_factor := lerpf(0.35, 1.0, player_energy_ratio())

	if reeling:
		player_energy = maxf(0.0, player_energy - 20.0 * delta)
		var effective_reel := reel_power * energy_factor
		var resistance := clampf(1.0 - fish_power * 0.12, 0.45, 1.0)
		distance -= effective_reel * resistance * delta
		var in_safe_zone := tension >= safe_min() and tension <= safe_max()
		var stamina_damage_multiplier := 1.28 if in_safe_zone else 0.48
		fish_stamina = maxf(0.0, fish_stamina - effective_reel * stamina_damage_multiplier * delta)
		tension += (0.15 + fish_power * 0.095) * delta
	elif giving_line:
		player_energy = minf(player_energy_max, player_energy + energy_regen * delta)
		distance += fish_power * fish_speed * 0.75 * delta
		tension -= (0.42 - minf(0.12, fish_power * 0.035)) * delta
	else:
		player_energy = minf(player_energy_max, player_energy + energy_regen * delta)
		distance += maxf(0.0, fish_power - 0.80) * fish_speed * 0.38 * delta
		tension += (fish_power - 0.72) * 0.095 * delta
		tension -= 0.035 * delta

	if action_name == "休む":
		fish_stamina = minf(fish_stamina_max, fish_stamina + 1.8 * delta)

	distance = clampf(distance, 0.0, initial_distance * 1.45)
	tension = clampf(tension, 0.0, line_break_limit() + 0.15)
	depth = clampf(depth, 2.0, 24.0)

	if tension < 0.055:
		_slack_timer += delta
	else:
		_slack_timer = maxf(0.0, _slack_timer - delta * 1.5)

	if tension > line_break_limit():
		_escape("テンションが上がりすぎてラインが切れた。")
		return
	if _slack_timer > 1.25:
		_escape("糸が緩みすぎて針が外れた。")
		return

	if distance <= 0.8 and fish_stamina_ratio() <= 0.22:
		_catch_fish()
		return

	_update_visual_position(delta, fish_speed)


func _choose_fish_action() -> void:
	var boss := bool(fish_data.get("boss", false))
	var profile: Dictionary = fish_data.get("action_profile", {})
	var messages: Dictionary = fish_data.get("action_messages", {})
	var dash_weight := float(profile.get("dash", 0.34 if boss else 0.30))
	var dive_weight := float(profile.get("dive", 0.26 if boss else 0.22))
	var turn_weight := float(profile.get("turn", 0.20 if boss else 0.21))
	var rest_weight := float(profile.get("rest", 0.20 if boss else 0.27))
	var total_weight := maxf(0.01, dash_weight + dive_weight + turn_weight + rest_weight)
	var roll := _rng.randf()
	var dash_cut := dash_weight / total_weight
	var dive_cut := dash_cut + dive_weight / total_weight
	var turn_cut := dive_cut + turn_weight / total_weight
	if boss:
		if roll < dash_cut:
			_set_action("突進", 1.75, _rng.randf_range(0.75, 1.25), String(messages.get("dash", "ぬしが激しく突進した！ 巻くのを止めよう！")))
			tension += 0.075
		elif roll < dive_cut:
			_set_action("潜水", 1.45, _rng.randf_range(0.95, 1.45), String(messages.get("dive", "ぬしが海底へ潜る！ 糸を出して耐えよう！")))
			depth += _rng.randf_range(_motion_value("dive_depth_min", 1.8), _motion_value("dive_depth_max", 3.2))
			tension += 0.045
		elif roll < turn_cut:
			_set_action("反転", 1.20, _rng.randf_range(0.55, 0.90), String(messages.get("turn", "急反転！ テンションの変化に注意！")))
			visual_direction *= -1.0
			tension += 0.035
		else:
			_set_action("休む", 0.38, _rng.randf_range(0.65, 1.05), String(messages.get("rest", "ぬしの動きが鈍った。今が巻き時だ！")))
	else:
		if roll < dash_cut:
			_set_action("突進", 1.48, _rng.randf_range(0.65, 1.10), String(messages.get("dash", "魚が走った！ 無理に巻かず耐えよう！")))
			tension += 0.045
		elif roll < dive_cut:
			_set_action("潜水", 1.22, _rng.randf_range(0.70, 1.20), String(messages.get("dive", "魚が深く潜ろうとしている！")))
			depth += _rng.randf_range(_motion_value("dive_depth_min", 0.8), _motion_value("dive_depth_max", 2.0))
		elif roll < turn_cut:
			_set_action("方向転換", 1.02, _rng.randf_range(0.55, 0.90), String(messages.get("turn", "魚が方向を変えた。ゲージをよく見よう。")))
			visual_direction *= -1.0
		else:
			_set_action("休む", 0.40, _rng.randf_range(0.70, 1.15), String(messages.get("rest", "魚が疲れている。巻き上げるチャンス！")))


func _set_action(name: String, multiplier: float, duration: float, text: String) -> void:
	action_name = name
	_action_multiplier = multiplier
	_action_timer = duration
	_set_message(text)


func _update_visual_position(delta: float, fish_speed: float) -> void:
	var distance_factor := clampf(distance / initial_distance, 0.0, 1.3)
	var target_x := lerpf(0.78, 0.28, distance_factor / 1.3)
	var wave_freq := _motion_value("wave_freq", 2.2 + fish_speed)
	var wave_amp := _motion_value("wave_amp", 0.018)
	var jitter := _motion_value("jitter", 0.0)
	target_x += sin(_visual_time * wave_freq * 2.1) * jitter
	var target_y := clampf(depth / 25.0 + _motion_value("depth_bias", 0.0), 0.22, 0.84)
	var wave := sin(_visual_time * wave_freq) * wave_amp
	visual_position.x = lerpf(visual_position.x, target_x, minf(1.0, delta * 1.8))
	visual_position.y = lerpf(visual_position.y, target_y + wave, minf(1.0, delta * 1.8))
	if action_name == "突進":
		visual_position.x -= visual_direction * delta * _motion_value("dash_shift", 0.05) * fish_speed
	elif action_name == "潜水":
		visual_position.y += delta * _motion_value("dive_shift", 0.040) * fish_speed
	elif action_name == "反転" or action_name == "方向転換":
		visual_position.x += visual_direction * delta * _motion_value("turn_shift", 0.035)
	visual_position.x = clampf(visual_position.x, 0.14, 0.86)
	visual_position.y = clampf(visual_position.y, 0.22, 0.84)


func _motion_value(key: String, fallback: float) -> float:
	var motion: Dictionary = fish_data.get("motion", {})
	return float(motion.get(key, fallback))


func _catch_fish() -> void:
	reeling = false
	giving_line = false
	result_size_cm = GameData.roll_fish_size(fish_data)
	action_name = "釣り上げ"
	_set_message("釣り上げた！")
	_set_state(State.CAUGHT)
	fight_finished.emit(true, "釣り上げ成功")


func _escape(reason: String) -> void:
	reeling = false
	giving_line = false
	action_name = "逃走"
	_set_message(reason)
	_set_state(State.ESCAPED)
	fight_finished.emit(false, reason)


func _set_state(new_state: int) -> void:
	state = new_state
	state_changed.emit(state)


func _set_message(text: String) -> void:
	action_message = text
	message_changed.emit(text)
