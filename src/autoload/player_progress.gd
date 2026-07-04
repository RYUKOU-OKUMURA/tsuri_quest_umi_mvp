extends Node

signal progress_changed
signal level_up(new_level: int)
signal fish_caught(fish_id: String, size_cm: float)
signal dish_eaten(recipe_id: String, gained_exp: int)

const SAVE_PATH := "user://tsuri_quest_save.json"
const SAVE_BACKUP_PATH := "user://tsuri_quest_save.json.bak"
const SAVE_TMP_PATH := "user://tsuri_quest_save.json.tmp"
const SAVE_VERSION := 1
const EXP_REQUIREMENTS: Array[int] = [0, 60, 85, 115, 150, 190, 235, 285, 340, 400, 0]

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

# smoke / preview / audit（res://tools/ 配下のシーン起動）から本番セーブを守るフラグ。
# true の間はディスクへの読み書きを一切行わない。
var _sandbox_mode := false


func _ready() -> void:
	_sandbox_mode = _detect_sandbox_mode()
	if _sandbox_mode:
		print("PlayerProgress: サンドボックスモードで起動（セーブファイルの読み書きを無効化）")
		return
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


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_BACKUP_PATH)


func reset_game() -> void:
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
	save_game()
	progress_changed.emit()


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
	var catch_result := {
		"fish_id": fish_id,
		"first_catch": previous_count <= 0,
		"boss_first_clear_reward": {},
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


func get_base_stats() -> Dictionary:
	var rod := GameData.get_rod(equipped_rod_id)
	var technique_points := (level - 1) + int(rod.get("technique_bonus", 0))
	return {
		"level": level,
		"max_energy": 100.0 + float(level - 1) * 5.0,
		"reel_power": (5.6 + float(level - 1) * 0.58) * float(rod.get("reel_multiplier", 1.0)),
		"technique": technique_points,
		"focus": level - 1,
		"energy_regen": 14.0 + float(level - 1) * 0.45,
		"bite_window_bonus": float(level - 1) * 0.025,
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


func save_game() -> void:
	if _sandbox_mode:
		return
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
	}
	# 一時ファイルへ書き切ってから差し替える（書き込み途中のクラッシュで本体を壊さない）
	var tmp_file := FileAccess.open(SAVE_TMP_PATH, FileAccess.WRITE)
	if tmp_file == null:
		push_warning("セーブファイルを開けませんでした: %s" % SAVE_TMP_PATH)
		return
	tmp_file.store_string(JSON.stringify(data, "\t"))
	tmp_file.close()

	# 直前の正常な本体を1世代バックアップとして残す
	if FileAccess.file_exists(SAVE_PATH):
		var backup_err := DirAccess.rename_absolute(SAVE_PATH, SAVE_BACKUP_PATH)
		if backup_err != OK:
			push_warning("セーブのバックアップ作成に失敗しました（コード: %d）" % backup_err)
	var rename_err := DirAccess.rename_absolute(SAVE_TMP_PATH, SAVE_PATH)
	if rename_err != OK:
		push_warning("セーブファイルの差し替えに失敗しました（コード: %d）" % rename_err)


func load_game() -> void:
	if _sandbox_mode:
		return
	var data := _read_save_dictionary(SAVE_PATH)
	if data.is_empty():
		var backup := _read_save_dictionary(SAVE_BACKUP_PATH)
		if backup.is_empty():
			if FileAccess.file_exists(SAVE_PATH):
				push_warning("セーブデータが壊れているため初期値を使用します。")
			return
		push_warning("セーブデータが壊れていたため、バックアップから復元します。")
		data = backup
	_apply_save_data(_migrate_save_data(data))


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
