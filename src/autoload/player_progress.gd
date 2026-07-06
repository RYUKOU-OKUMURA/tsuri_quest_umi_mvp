extends Node

signal progress_changed
signal level_up(new_level: int)
signal fish_caught(fish_id: String, size_cm: float)
signal dish_eaten(recipe_id: String, gained_exp: int)
signal titles_earned(title_ids: Array[String])

const SAVE_SLOT_COUNT := 3
const DEFAULT_SAVE_SLOT := 1
const SAVE_SLOT_ROOT := "user://slots"
const SAVE_FILE_NAME := "tsuri_quest_save.json"
const SAVE_BACKUP_FILE_NAME := "tsuri_quest_save.json.bak"
const SAVE_TMP_FILE_NAME := "tsuri_quest_save.json.tmp"
const LEGACY_SAVE_PATH := "user://tsuri_quest_save.json"
const LEGACY_SAVE_BACKUP_PATH := "user://tsuri_quest_save.json.bak"
const LEGACY_SAVE_TMP_PATH := "user://tsuri_quest_save.json.tmp"
const SAVE_VERSION := 1
const EXP_REQUIREMENTS: Array[int] = [
	0,
	60,
	85,
	115,
	150,
	190,
	235,
	285,
	340,
	400,
	460,
	520,
	580,
	640,
	700,
	770,
	840,
	910,
	980,
	1050,
	1130,
	1210,
	1290,
	1370,
	1450,
	1540,
	1630,
	1720,
	1810,
	1900,
	2000,
	2100,
	2200,
	2300,
	2400,
	2500,
	2600,
	2700,
	2800,
	2900,
	3050,
	3200,
	3350,
	3500,
	3650,
	3800,
	3950,
	4100,
	4250,
	4400,
	0,
]
const GROWTH_SOFT_CAP := 10
const GROWTH_RATE_AFTER_CAP := 0.35
const GROWTH_SOFT_CAP_2 := 30
const GROWTH_RATE_AFTER_CAP_2 := 0.10

var level: int = 1
var exp: int = 0
var money: int = 500
var inventory: Dictionary = {}
var caught_counts: Dictionary = {}
var spot_caught_counts: Dictionary = {}
var best_sizes: Dictionary = {}
var eaten_recipes: Dictionary = {}
var owned_rods: Array[String] = ["starter"]
var equipped_rod_id: String = "starter"
var owned_rigs: Array[String] = [GameData.DEFAULT_RIG_ID]
var equipped_rig_id: String = GameData.DEFAULT_RIG_ID
var owned_boats: Array[String] = []
var pending_buff: Dictionary = {}
var play_seconds: float = 0.0
var active_save_slot: int = DEFAULT_SAVE_SLOT
var quest_board: Array[Dictionary] = []
var quest_completed_count: int = 0

# smoke / preview / audit（res://tools/ 配下のシーン起動）から本番セーブを守るフラグ。
# true の間はディスクへの読み書きを一切行わない。
var _sandbox_mode := false
var _known_title_ids: Array[String] = []


func _ready() -> void:
	_sandbox_mode = _detect_sandbox_mode()
	if _sandbox_mode:
		print("PlayerProgress: サンドボックスモードで起動（セーブファイルの読み書きを無効化）")
		_remember_current_titles()
		return
	_migrate_legacy_save_files()
	load_game()


func _detect_sandbox_mode() -> bool:
	if OS.get_environment("TSURI_QA_SANDBOX") == "1":
		return true
	# シェル経由でも エディタの「シーンを実行」でも、起動シーンはコマンドライン引数に載る
	for arg_variant in OS.get_cmdline_args():
		var arg := String(arg_variant)
		if arg.ends_with(".tscn") and arg.contains("tools/"):
			return true
	return false


func is_sandbox_mode() -> bool:
	return _sandbox_mode


func _process(delta: float) -> void:
	play_seconds += delta


func current_save_path() -> String:
	return _slot_save_path(active_save_slot)


func current_backup_path() -> String:
	return _slot_backup_path(active_save_slot)


func current_tmp_path() -> String:
	return _slot_tmp_path(active_save_slot)


func has_save_file(slot_id: int = -1) -> bool:
	var resolved_slot := active_save_slot if slot_id < 1 else _normalized_slot(slot_id)
	return FileAccess.file_exists(_slot_save_path(resolved_slot)) or FileAccess.file_exists(
		_slot_backup_path(resolved_slot)
	)


func set_active_save_slot(slot_id: int, load_slot := true) -> void:
	active_save_slot = _normalized_slot(slot_id)
	_ensure_slot_dir(active_save_slot)
	if not load_slot:
		return
	_reset_runtime_state()
	if has_save_file(active_save_slot):
		load_game()
	else:
		_remember_current_titles()
		progress_changed.emit()


func save_slot_summary(slot_id: int) -> Dictionary:
	var resolved_slot := _normalized_slot(slot_id)
	var data := _read_save_dictionary(_slot_save_path(resolved_slot))
	if data.is_empty():
		data = _read_save_dictionary(_slot_backup_path(resolved_slot))
	var save_path := _slot_save_path(resolved_slot)
	var backup_path := _slot_backup_path(resolved_slot)
	var updated_unix := 0
	if FileAccess.file_exists(save_path):
		updated_unix = int(FileAccess.get_modified_time(save_path))
	elif FileAccess.file_exists(backup_path):
		updated_unix = int(FileAccess.get_modified_time(backup_path))
	return {
		"slot_id": resolved_slot,
		"active": resolved_slot == active_save_slot,
		"has_save": not data.is_empty(),
		"level": int(data.get("level", 1)),
		"money": int(data.get("money", 0)),
		"play_seconds": float(data.get("play_seconds", 0.0)),
		"updated_unix": updated_unix,
	}


func reset_game() -> void:
	_reset_runtime_state()
	_remember_current_titles()
	save_game()
	progress_changed.emit()


func _reset_runtime_state() -> void:
	level = 1
	exp = 0
	money = 500
	inventory = {}
	caught_counts = {}
	spot_caught_counts = {}
	best_sizes = {}
	eaten_recipes = {}
	owned_rods = ["starter"]
	equipped_rod_id = "starter"
	owned_rigs = [GameData.DEFAULT_RIG_ID]
	equipped_rig_id = GameData.DEFAULT_RIG_ID
	owned_boats = []
	pending_buff = {}
	play_seconds = 0.0
	quest_board = []
	quest_completed_count = 0


func exp_to_next_level() -> int:
	if level >= GameData.MAX_LEVEL:
		return 0
	return EXP_REQUIREMENTS[level]


func add_exp(amount: int) -> Array[int]:
	var leveled_to: Array[int] = []
	if amount <= 0 or level >= GameData.MAX_LEVEL:
		return leveled_to

	exp += amount
	while level < GameData.MAX_LEVEL:
		var required := exp_to_next_level()
		if required <= 0 or exp < required:
			break
		exp -= required
		level += 1
		leveled_to.append(level)
		level_up.emit(level)

	if level >= GameData.MAX_LEVEL:
		exp = 0
	return leveled_to


func record_catch(fish_id: String, size_cm: float, spot_id: String = "") -> Dictionary:
	var fish := GameData.get_fish(fish_id)
	var previous_count := int(caught_counts.get(fish_id, 0))
	var previous_best := float(best_sizes.get(fish_id, 0.0))
	var catch_result := {
		"fish_id": fish_id,
		"first_catch": previous_count <= 0,
		"boss_first_clear_reward": {},
		"record_broken": previous_count > 0 and size_cm > previous_best,
		"previous_best_cm": previous_best,
		"new_titles": [],
	}
	inventory[fish_id] = int(inventory.get(fish_id, 0)) + 1
	caught_counts[fish_id] = previous_count + 1
	if not spot_id.is_empty():
		var spot_counts: Dictionary = {}
		var loaded_spot_counts = spot_caught_counts.get(spot_id, {})
		if typeof(loaded_spot_counts) == TYPE_DICTIONARY:
			spot_counts = loaded_spot_counts.duplicate(true)
		spot_counts[fish_id] = int(spot_counts.get(fish_id, 0)) + 1
		spot_caught_counts[spot_id] = spot_counts
	best_sizes[fish_id] = maxf(float(best_sizes.get(fish_id, 0.0)), size_cm)
	if previous_count <= 0 and bool(fish.get("boss", false)):
		var reward := GameData.get_boss_first_clear_reward(fish_id)
		var reward_money := int(reward.get("money", 0))
		if reward_money > 0:
			money += reward_money
		catch_result["boss_first_clear_reward"] = reward
	catch_result["new_titles"] = _award_new_titles()
	fish_caught.emit(fish_id, size_cm)
	save_game()
	progress_changed.emit()
	return catch_result


func fish_count(fish_id: String) -> int:
	return int(inventory.get(fish_id, 0))


func sell_fish(fish_id: String, amount: int) -> Dictionary:
	var fish := GameData.get_fish(fish_id)
	var current := fish_count(fish_id)
	if fish.is_empty() or amount <= 0 or current < amount:
		return {"ok": false, "message": "売却できる魚が足りません。"}

	var income := int(fish["sell_price"]) * amount
	inventory[fish_id] = current - amount
	money += income
	save_game()
	progress_changed.emit()
	return {"ok": true, "income": income, "amount": amount}


func sell_fish_batch(orders: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	var sold: Dictionary = {}
	var income := 0
	var total_amount := 0

	for key in orders.keys():
		var fish_id := String(key)
		var amount := int(orders[key])
		if amount <= 0:
			continue
		var fish := GameData.get_fish(fish_id)
		var current := fish_count(fish_id)
		if fish.is_empty() or current < amount:
			return {
				"ok": false,
				"income": 0,
				"total_amount": 0,
				"sold": {},
				"message": "売却できる魚が足りません。",
			}
		normalized[fish_id] = amount
		income += int(fish["sell_price"]) * amount
		total_amount += amount

	if normalized.is_empty():
		return {
			"ok": false,
			"income": 0,
			"total_amount": 0,
			"sold": {},
			"message": "売る魚を選んでください。",
		}

	for fish_id in normalized.keys():
		var amount := int(normalized[fish_id])
		var fish := GameData.get_fish(fish_id)
		var item_income := int(fish["sell_price"]) * amount
		inventory[fish_id] = fish_count(fish_id) - amount
		sold[fish_id] = {
			"amount": amount,
			"income": item_income,
		}

	money += income
	save_game()
	progress_changed.emit()
	return {
		"ok": true,
		"income": income,
		"total_amount": total_amount,
		"sold": sold,
		"message": "%d匹売って、%d Gを受け取った。" % [total_amount, income],
	}


func ensure_quest_board() -> void:
	var changed := false
	while quest_board.size() < 3:
		var quest := GameData.generate_quest(_quest_generation_context())
		if quest.is_empty():
			break
		quest_board.append(quest)
		changed = true
	if changed:
		save_game()
		progress_changed.emit()


func quest_progress(index: int) -> Dictionary:
	if index < 0 or index >= quest_board.size():
		return {}
	return GameData.quest_progress(quest_board[index], _quest_stats_snapshot())


func deliver_quest(index: int) -> Dictionary:
	ensure_quest_board()
	if index < 0 or index >= quest_board.size():
		return {"ok": false, "message": "依頼が見つかりません。"}
	var quest := quest_board[index].duplicate(true)
	var progress := GameData.quest_progress(quest, _quest_stats_snapshot())
	if not bool(progress.get("completed", false)):
		return {"ok": false, "message": "まだ依頼を達成していません。", "progress": progress}

	var kind := String(quest.get("kind", "delivery"))
	var fish_id := String(quest.get("fish_id", ""))
	if kind == "delivery":
		var required_count := int(quest.get("count", 0))
		var current_count := fish_count(fish_id)
		if current_count < required_count:
			return {"ok": false, "message": "納品する魚が足りません。", "progress": progress}
		inventory[fish_id] = current_count - required_count

	var reward := int(quest.get("reward_money", 0))
	money += reward
	quest_completed_count += 1
	var rig_awarded := _award_quest_reward_rig()
	var new_titles := _award_new_titles()
	var replacement := GameData.generate_quest(_quest_generation_context([quest]))
	quest_board.remove_at(index)
	if not replacement.is_empty():
		quest_board.insert(index, replacement)
	save_game()
	progress_changed.emit()
	return {
		"ok": true,
		"quest": quest,
		"replacement": replacement,
		"reward_money": reward,
		"quest_completed_count": quest_completed_count,
		"rig_awarded": rig_awarded,
		"new_titles": new_titles,
		"message": "依頼達成！ %d Gを受け取った。" % reward,
	}


func cook_and_eat(fish_id: String, recipe_id: String) -> Dictionary:
	var fish := GameData.get_fish(fish_id)
	var recipe := GameData.get_recipe(recipe_id)
	if fish.is_empty() or recipe.is_empty():
		return {"ok": false, "message": "魚または料理データが見つかりません。"}
	if fish_count(fish_id) <= 0:
		return {"ok": false, "message": "その魚を持っていません。"}
	if level < int(recipe["unlock_level"]):
		return {"ok": false, "message": "まだこの料理は作れません。"}
	if fish_id not in recipe["allowed_fish"]:
		return {"ok": false, "message": "この魚には選んだ調理法を使えません。"}

	inventory[fish_id] = fish_count(fish_id) - 1
	var base_exp := GameData.recipe_exp(fish_id, recipe_id)
	var dish_key := "%s:%s" % [fish_id, recipe_id]
	var first_time := not eaten_recipes.has(dish_key)
	var first_bonus := base_exp if first_time else 0
	var total_exp := base_exp + first_bonus
	eaten_recipes[dish_key] = int(eaten_recipes.get(dish_key, 0)) + 1
	pending_buff = {
		"recipe_id": recipe_id,
		"name": "%sの%s" % [String(fish["name"]), String(recipe["name"])],
		"stat": String(recipe["buff_stat"]),
		"value": float(recipe["buff_value"]),
		"text": String(recipe["buff_text"]),
	}
	var leveled_to := add_exp(total_exp)
	dish_eaten.emit(recipe_id, total_exp)
	var new_titles := _award_new_titles()
	save_game()
	progress_changed.emit()
	return {
		"ok": true,
		"dish_name": pending_buff["name"],
		"base_exp": base_exp,
		"first_time": first_time,
		"first_bonus": first_bonus,
		"total_exp": total_exp,
		"leveled_to": leveled_to,
		"buff": pending_buff.duplicate(true),
		"new_titles": new_titles,
	}


func buy_or_equip_rod(rod_id: String) -> Dictionary:
	var rod := GameData.get_rod(rod_id)
	if rod.is_empty():
		return {"ok": false, "message": "竿データが見つかりません。"}

	if rod_id in owned_rods:
		equipped_rod_id = rod_id
		save_game()
		progress_changed.emit()
		return {"ok": true, "action": "equip", "message": "%sを装備しました。" % rod["name"]}

	var price := int(rod["price"])
	if money < price:
		return {"ok": false, "message": "所持金が足りません。"}
	money -= price
	owned_rods.append(rod_id)
	equipped_rod_id = rod_id
	save_game()
	progress_changed.emit()
	return {"ok": true, "action": "buy", "message": "%sを購入して装備しました。" % rod["name"]}


func buy_or_equip_rig(rig_id: String) -> Dictionary:
	var rig := GameData.get_rig(rig_id)
	if rig.is_empty():
		return {"ok": false, "message": "仕掛けデータが見つかりません。"}

	if rig_id in owned_rigs:
		equipped_rig_id = rig_id
		save_game()
		progress_changed.emit()
		return {"ok": true, "action": "equip", "message": "%sを装備しました。" % rig["name"]}

	var unlock_level := int(rig.get("unlock_level", 1))
	if level < unlock_level:
		return {"ok": false, "message": "%sはLv.%dで解放されます。" % [rig["name"], unlock_level]}

	var price := int(rig["price"])
	if money < price:
		return {"ok": false, "message": "所持金が足りません。"}
	money -= price
	owned_rigs.append(rig_id)
	equipped_rig_id = rig_id
	save_game()
	progress_changed.emit()
	return {"ok": true, "action": "buy", "message": "%sを購入して装備しました。" % rig["name"]}


func has_boat(boat_id: String) -> bool:
	return boat_id in owned_boats


func best_boat_rank() -> int:
	return GameData.get_best_boat_rank(owned_boats)


func get_best_boat() -> Dictionary:
	var best_boat: Dictionary = {}
	var best_rank := GameData.NO_BOAT_RANK
	for boat_id in owned_boats:
		var boat := GameData.get_boat(boat_id)
		if boat.is_empty():
			continue
		var rank := int(boat.get("rank", GameData.NO_BOAT_RANK))
		if rank > best_rank:
			best_rank = rank
			best_boat = boat
	return best_boat


func buy_boat(boat_id: String) -> Dictionary:
	var boat := GameData.get_boat(boat_id)
	if boat.is_empty():
		return {"ok": false, "message": "船データが見つかりません。"}
	if has_boat(boat_id):
		return {"ok": false, "message": "%sはすでに所持しています。" % boat["name"]}

	var price := int(boat["price"])
	if money < price:
		return {"ok": false, "message": "所持金が足りません。"}
	money -= price
	owned_boats.append(boat_id)
	save_game()
	progress_changed.emit()
	return {"ok": true, "action": "buy_boat", "message": "%sを購入しました。%s。" % [boat["name"], boat["access_text"]]}


func fishing_spot_access_status(spot_id: String) -> Dictionary:
	return GameData.fishing_spot_access_status(spot_id, level, owned_boats)


func can_access_fishing_spot(spot_id: String) -> bool:
	return bool(fishing_spot_access_status(spot_id).get("ok", false))


func growth_points() -> float:
	if level <= GROWTH_SOFT_CAP:
		return float(level - 1)
	if level <= GROWTH_SOFT_CAP_2:
		return (
			float(GROWTH_SOFT_CAP - 1)
			+ float(level - GROWTH_SOFT_CAP) * GROWTH_RATE_AFTER_CAP
		)
	return (
		float(GROWTH_SOFT_CAP - 1)
		+ float(GROWTH_SOFT_CAP_2 - GROWTH_SOFT_CAP) * GROWTH_RATE_AFTER_CAP
		+ float(level - GROWTH_SOFT_CAP_2) * GROWTH_RATE_AFTER_CAP_2
	)


func get_base_stats() -> Dictionary:
	var rod := GameData.get_rod(equipped_rod_id)
	var growth := growth_points()
	var growth_floor := int(floor(growth))
	var technique_points := growth_floor + int(rod.get("technique_bonus", 0))
	return {
		"level": level,
		"max_energy": 100.0 + growth * 5.0,
		"reel_power": (5.6 + growth * 0.58) * float(rod.get("reel_multiplier", 1.0)),
		"technique": technique_points,
		"focus": growth_floor,
		"energy_regen": 14.0 + growth * 0.45,
		"bite_window_bonus": growth * 0.025,
		"safe_min": maxf(0.10, 0.22 - float(technique_points) * 0.007),
		"safe_max": minf(0.88, 0.72 + float(technique_points) * 0.010),
		"line_break_limit": 1.0 + float(rod.get("line_limit_bonus", 0.0)),
		"rod_name": String(rod.get("name", "港の入門竿")),
	}


func begin_fishing_trip() -> Dictionary:
	var stats := get_base_stats()
	var environment := GameData.roll_fishing_environment()
	var applied_buff := pending_buff.duplicate(true)
	if not applied_buff.is_empty():
		match String(applied_buff.get("stat", "")):
			"max_energy":
				stats["max_energy"] *= 1.0 + float(applied_buff["value"])
			"bite_window":
				stats["bite_window_bonus"] += float(applied_buff["value"])
			"safe_range":
				stats["safe_min"] = maxf(
					0.06, float(stats["safe_min"]) - float(applied_buff["value"]) * 0.5
				)
				stats["safe_max"] = minf(
					0.94, float(stats["safe_max"]) + float(applied_buff["value"]) * 0.5
				)
			"energy_regen":
				stats["energy_regen"] *= 1.0 + float(applied_buff["value"])
			"reel_power":
				stats["reel_power"] *= 1.0 + float(applied_buff["value"])
	stats["meal_buff"] = applied_buff
	stats["environment_id"] = String(environment.get("id", GameData.DEFAULT_FISHING_ENVIRONMENT_ID))
	stats["weather_id"] = String(environment.get("weather_id", "sunny"))
	stats["weather_label"] = String(environment.get("weather_label", "快晴"))
	stats["wind_id"] = String(environment.get("wind_id", "weak"))
	stats["wind_label"] = String(environment.get("wind_label", "風 弱"))
	stats["surface_bgm_key"] = String(environment.get("surface_bgm_key", "calm"))
	var rig := GameData.get_rig(equipped_rig_id)
	if rig.is_empty():
		equipped_rig_id = GameData.DEFAULT_RIG_ID
		rig = GameData.get_rig(equipped_rig_id)
	stats["rig_id"] = String(rig.get("id", GameData.DEFAULT_RIG_ID))
	stats["rig_name"] = String(rig.get("name", "サビキ仕掛け"))
	stats["rig_bait_types"] = GameData.rig_bait_types(equipped_rig_id)
	pending_buff = {}
	save_game()
	progress_changed.emit()
	return stats


func title_stats_snapshot() -> Dictionary:
	return {
		"level": level,
		"caught_counts": caught_counts.duplicate(true),
		"spot_caught_counts": spot_caught_counts.duplicate(true),
		"best_sizes": best_sizes.duplicate(true),
		"eaten_recipes": eaten_recipes.duplicate(true),
		"quest_completed_count": quest_completed_count,
		"shark_bonds": {},
	}


func _quest_stats_snapshot() -> Dictionary:
	return {
		"inventory": inventory.duplicate(true),
		"best_sizes": best_sizes.duplicate(true),
	}


func _quest_generation_context(extra_excluded_quests: Array = []) -> Dictionary:
	var existing: Array[Dictionary] = []
	for quest in quest_board:
		existing.append(quest.duplicate(true))
	for quest_variant in extra_excluded_quests:
		if typeof(quest_variant) == TYPE_DICTIONARY:
			existing.append(Dictionary(quest_variant).duplicate(true))
	return {
		"player_level": level,
		"owned_boats": owned_boats.duplicate(true),
		"existing_quests": existing,
		"best_sizes": best_sizes.duplicate(true),
	}


func _award_quest_reward_rig() -> bool:
	if quest_completed_count < 10 or "shokunin" in owned_rigs:
		return false
	if GameData.get_rig("shokunin").is_empty():
		return false
	owned_rigs.append("shokunin")
	return true


func save_game() -> void:
	if _sandbox_mode:
		return
	_ensure_slot_dir(active_save_slot)
	var data := {
		"version": SAVE_VERSION,
		"level": level,
		"exp": exp,
		"money": money,
		"inventory": inventory,
		"caught_counts": caught_counts,
		"spot_caught_counts": spot_caught_counts,
		"best_sizes": best_sizes,
		"eaten_recipes": eaten_recipes,
		"owned_rods": owned_rods,
		"equipped_rod_id": equipped_rod_id,
		"owned_rigs": owned_rigs,
		"equipped_rig_id": equipped_rig_id,
		"owned_boats": owned_boats,
		"pending_buff": pending_buff,
		"play_seconds": play_seconds,
		"quest_board": quest_board,
		"quest_completed_count": quest_completed_count,
	}
	var save_path := current_save_path()
	var backup_path := current_backup_path()
	var tmp_path := current_tmp_path()
	# 一時ファイルへ書き切ってから差し替える（書き込み途中のクラッシュで本体を壊さない）
	var tmp_file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if tmp_file == null:
		push_warning("セーブファイルを開けませんでした: %s" % tmp_path)
		return
	tmp_file.store_string(JSON.stringify(data, "\t"))
	tmp_file.close()

	# 直前の正常な本体を1世代バックアップとして残す
	if FileAccess.file_exists(save_path):
		var backup_err := DirAccess.rename_absolute(save_path, backup_path)
		if backup_err != OK:
			push_warning("セーブのバックアップ作成に失敗しました（コード: %d）" % backup_err)
	var rename_err := DirAccess.rename_absolute(tmp_path, save_path)
	if rename_err != OK:
		push_warning("セーブファイルの差し替えに失敗しました（コード: %d）" % rename_err)


func load_game() -> void:
	if _sandbox_mode:
		_remember_current_titles()
		return
	var save_path := current_save_path()
	var backup_path := current_backup_path()
	var data := _read_save_dictionary(save_path)
	if data.is_empty():
		var backup := _read_save_dictionary(backup_path)
		if backup.is_empty():
			if FileAccess.file_exists(save_path):
				push_warning("セーブデータが壊れているため初期値を使用します。")
			_remember_current_titles()
			return
		push_warning("セーブデータが壊れていたため、バックアップから復元します。")
		data = backup
	_apply_save_data(_migrate_save_data(data))
	_remember_current_titles()


func _read_save_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _migrate_legacy_save_files() -> void:
	_ensure_slot_dir(DEFAULT_SAVE_SLOT)
	_move_legacy_save_file(LEGACY_SAVE_PATH, _slot_save_path(DEFAULT_SAVE_SLOT))
	_move_legacy_save_file(LEGACY_SAVE_BACKUP_PATH, _slot_backup_path(DEFAULT_SAVE_SLOT))
	_move_legacy_save_file(LEGACY_SAVE_TMP_PATH, _slot_tmp_path(DEFAULT_SAVE_SLOT))


func _move_legacy_save_file(from_path: String, to_path: String) -> void:
	if not FileAccess.file_exists(from_path) or FileAccess.file_exists(to_path):
		return
	var err := DirAccess.rename_absolute(from_path, to_path)
	if err != OK:
		push_warning("旧セーブの移行に失敗しました（%s → %s / code %d）" % [from_path, to_path, err])


func _normalized_slot(slot_id: int) -> int:
	return clampi(slot_id, 1, SAVE_SLOT_COUNT)


func _slot_dir(slot_id: int) -> String:
	return "%s/%d" % [SAVE_SLOT_ROOT, _normalized_slot(slot_id)]


func _slot_save_path(slot_id: int) -> String:
	return "%s/%s" % [_slot_dir(slot_id), SAVE_FILE_NAME]


func _slot_backup_path(slot_id: int) -> String:
	return "%s/%s" % [_slot_dir(slot_id), SAVE_BACKUP_FILE_NAME]


func _slot_tmp_path(slot_id: int) -> String:
	return "%s/%s" % [_slot_dir(slot_id), SAVE_TMP_FILE_NAME]


func _ensure_slot_dir(slot_id: int) -> void:
	var err := DirAccess.make_dir_recursive_absolute(_slot_dir(slot_id))
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_warning("セーブスロットディレクトリを作成できませんでした（code %d）" % err)


func _migrate_save_data(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	if version > SAVE_VERSION:
		push_warning(
			"新しいバージョンのセーブデータです（version %d > %d）。読み込みを試みます。"
			% [version, SAVE_VERSION]
		)
		return data
	# version が上がったらここに旧版→新版の変換を追加する。
	# _apply_save_data() は欠損フィールドをデフォルト値で補完するため、
	# フィールド追加だけの変更なら変換は不要。
	return data


func _apply_save_data(data: Dictionary) -> void:
	level = clampi(int(data.get("level", 1)), 1, GameData.MAX_LEVEL)
	exp = maxi(0, int(data.get("exp", 0)))
	money = maxi(0, int(data.get("money", 500)))
	var loaded_inventory = data.get("inventory", {})
	var loaded_caught_counts = data.get("caught_counts", {})
	var loaded_spot_caught_counts = data.get("spot_caught_counts", {})
	var loaded_best_sizes = data.get("best_sizes", {})
	var loaded_eaten_recipes = data.get("eaten_recipes", {})
	var loaded_quest_board = data.get("quest_board", [])
	inventory = (
		loaded_inventory.duplicate(true) if typeof(loaded_inventory) == TYPE_DICTIONARY else {}
	)
	caught_counts = (
		loaded_caught_counts.duplicate(true)
		if typeof(loaded_caught_counts) == TYPE_DICTIONARY
		else {}
	)
	spot_caught_counts = (
		loaded_spot_caught_counts.duplicate(true)
		if typeof(loaded_spot_caught_counts) == TYPE_DICTIONARY
		else {}
	)
	best_sizes = (
		loaded_best_sizes.duplicate(true) if typeof(loaded_best_sizes) == TYPE_DICTIONARY else {}
	)
	eaten_recipes = (
		loaded_eaten_recipes.duplicate(true)
		if typeof(loaded_eaten_recipes) == TYPE_DICTIONARY
		else {}
	)
	quest_board = _normalized_quest_board(loaded_quest_board)
	quest_completed_count = maxi(0, int(data.get("quest_completed_count", 0)))
	owned_rods = []
	var loaded_rods = data.get("owned_rods", ["starter"])
	if typeof(loaded_rods) == TYPE_ARRAY:
		for rod_id_variant in loaded_rods:
			var rod_id := String(rod_id_variant)
			if not GameData.get_rod(rod_id).is_empty() and rod_id not in owned_rods:
				owned_rods.append(rod_id)
	if "starter" not in owned_rods:
		owned_rods.push_front("starter")
	equipped_rod_id = String(data.get("equipped_rod_id", "starter"))
	if equipped_rod_id not in owned_rods or GameData.get_rod(equipped_rod_id).is_empty():
		equipped_rod_id = "starter"
	owned_rigs = []
	var loaded_rigs = data.get("owned_rigs", [GameData.DEFAULT_RIG_ID])
	if typeof(loaded_rigs) == TYPE_ARRAY:
		for rig_id_variant in loaded_rigs:
			var rig_id := String(rig_id_variant)
			if not GameData.get_rig(rig_id).is_empty() and rig_id not in owned_rigs:
				owned_rigs.append(rig_id)
	if GameData.DEFAULT_RIG_ID not in owned_rigs:
		owned_rigs.push_front(GameData.DEFAULT_RIG_ID)
	equipped_rig_id = String(data.get("equipped_rig_id", GameData.DEFAULT_RIG_ID))
	if equipped_rig_id not in owned_rigs or GameData.get_rig(equipped_rig_id).is_empty():
		equipped_rig_id = GameData.DEFAULT_RIG_ID
	owned_boats = []
	var loaded_boats = data.get("owned_boats", [])
	if typeof(loaded_boats) == TYPE_ARRAY:
		for boat_id_variant in loaded_boats:
			var boat_id := String(boat_id_variant)
			if not GameData.get_boat(boat_id).is_empty() and boat_id not in owned_boats:
				owned_boats.append(boat_id)
	var loaded_buff = data.get("pending_buff", {})
	pending_buff = loaded_buff.duplicate(true) if typeof(loaded_buff) == TYPE_DICTIONARY else {}
	play_seconds = maxf(0.0, float(data.get("play_seconds", 0.0)))
	progress_changed.emit()


func _normalized_quest_board(value: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return normalized
	for quest_variant in Array(value):
		if typeof(quest_variant) != TYPE_DICTIONARY:
			continue
		var quest := Dictionary(quest_variant).duplicate(true)
		quest["template_id"] = String(quest.get("template_id", ""))
		quest["kind"] = String(quest.get("kind", "delivery"))
		quest["fish_id"] = String(quest.get("fish_id", ""))
		quest["count"] = int(quest.get("count", 0))
		quest["target_size_cm"] = float(quest.get("target_size_cm", 0.0))
		quest["posted_best_cm"] = float(quest.get("posted_best_cm", 0.0))
		quest["reward_money"] = int(quest.get("reward_money", 0))
		quest["text"] = String(quest.get("text", ""))
		if String(quest.get("fish_id", "")).is_empty() or String(quest.get("text", "")).is_empty():
			continue
		normalized.append(quest)
		if normalized.size() >= 3:
			break
	return normalized


func _remember_current_titles() -> void:
	_known_title_ids = GameData.compute_earned_titles(title_stats_snapshot())


func _award_new_titles() -> Array[String]:
	var earned_ids := GameData.compute_earned_titles(title_stats_snapshot())
	var new_ids: Array[String] = []
	for title_id in earned_ids:
		if title_id not in _known_title_ids:
			new_ids.append(title_id)
	_known_title_ids = earned_ids
	if not new_ids.is_empty():
		titles_earned.emit(new_ids)
	return new_ids
