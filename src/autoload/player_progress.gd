extends Node

const SaveNamespaceMigrator = preload("res://src/autoload/save_namespace_migrator.gd")

signal progress_changed
signal level_up(new_level: int)
signal fish_caught(fish_id: String, size_cm: float)
signal dish_eaten(recipe_id: String, gained_exp: int)
signal titles_earned(title_ids: Array[String])
signal save_failed(message: String)

const SAVE_SLOT_COUNT := 3
const DEFAULT_SAVE_SLOT := 1
const SAVE_SLOT_ROOT := "user://slots"
const SAVE_FILE_NAME := "tsuri_quest_save.json"
const SAVE_BACKUP_FILE_NAME := "tsuri_quest_save.json.bak"
const SAVE_TMP_FILE_NAME := "tsuri_quest_save.json.tmp"
const SAVE_VERSION := 1
const FUTURE_SAVE_GUARD_MESSAGE := "新しい版で作られたセーブのため、対応する新しい版で開いてください。"
const INVALID_SAVE_MESSAGE := "セーブデータとバックアップが壊れているため、読み込めませんでした。原本は変更していません。"
const INVALID_SAVE_TITLE_MESSAGE := "セーブ破損。原本は変更していません"
const INVALID_OUTBOUND_SAVE_MESSAGE := "進行データがセーブ可能な範囲を超えたため、原本を変更せず保存を中止しました。"
const INVALID_DIFFICULTY_MESSAGE := "選択した難易度が見つからないため、セーブを初期化できませんでした。"
const SAVE_STORAGE_MIGRATION_BLOCK_MESSAGE := SaveNamespaceMigrator.DEFAULT_FAILURE_MESSAGE
const SEA_CHART_FRAGMENT_MAX := 3
const MAX_SAFE_JSON_INTEGER := 9007199254740991
const DIFFICULTY_MULTIPLIER_SCALE := 10000
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
var sea_chart_fragments: int = 0
var shark_bonds: Dictionary = {}
var selected_time_slot_id: String = GameData.DEFAULT_TIME_SLOT_ID
var difficulty_id: String = GameData.DEFAULT_DIFFICULTY_ID

# smoke / preview / audit（res://tools/ 配下のシーン起動）から本番セーブを守るフラグ。
# true の間はディスクへの読み書きを一切行わない。
var _sandbox_mode := false
var _known_title_ids: Array[String] = []
# save_system_smoke 専用。通常実行では空文字のままにする。
var _save_failure_injection_stage := ""
var _save_storage_ready := true
var _save_storage_block_message := ""


func _ready() -> void:
	_sandbox_mode = _detect_sandbox_mode()
	if _sandbox_mode:
		print("PlayerProgress: サンドボックスモードで起動（セーブファイルの読み書きを無効化）")
		_remember_current_titles()
		return
	_initialize_save_storage()


func _initialize_save_storage() -> void:
	_save_storage_ready = false
	_save_storage_block_message = ""
	var migrator := SaveNamespaceMigrator.new(
		{
			"slot_count": SAVE_SLOT_COUNT,
			"default_slot": DEFAULT_SAVE_SLOT,
			"save_version": SAVE_VERSION,
			"save_file_name": SAVE_FILE_NAME,
			"backup_file_name": SAVE_BACKUP_FILE_NAME,
			"tmp_file_name": SAVE_TMP_FILE_NAME,
		}
	)
	var migration_result := migrator.run()
	if not bool(migration_result.get("ok", false)):
		_save_storage_block_message = String(
			migration_result.get("message", SAVE_STORAGE_MIGRATION_BLOCK_MESSAGE)
		)
		_reset_runtime_state()
		_remember_current_titles()
		_report_save_failure(_save_storage_block_message)
		return
	_save_storage_ready = true
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


func is_save_storage_blocked() -> bool:
	return not _save_storage_ready


func save_storage_block_message() -> String:
	return (
		_save_storage_block_message
		if not _save_storage_block_message.is_empty()
		else SAVE_STORAGE_MIGRATION_BLOCK_MESSAGE
	)


func _process(delta: float) -> void:
	play_seconds += delta


func current_save_path() -> String:
	return _slot_save_path(active_save_slot)


func current_backup_path() -> String:
	return _slot_backup_path(active_save_slot)


func current_tmp_path() -> String:
	return _slot_tmp_path(active_save_slot)


func has_save_file(slot_id: int = -1) -> bool:
	if not _save_storage_ready:
		return false
	var resolved_slot := active_save_slot if slot_id < 1 else _normalized_slot(slot_id)
	return FileAccess.file_exists(_slot_save_path(resolved_slot)) or FileAccess.file_exists(
		_slot_backup_path(resolved_slot)
	)


func future_save_guard_status(slot_id: int = -1) -> Dictionary:
	var resolved_slot := active_save_slot if slot_id < 1 else _normalized_slot(slot_id)
	if not _save_storage_ready:
		return {
			"guarded": false,
			"slot_id": resolved_slot,
			"version": 0,
			"version_type": TYPE_NIL,
			"reason": "storage_blocked",
			"path": "",
		}
	for path in _slot_save_paths(resolved_slot):
		var data := _read_save_dictionary(path)
		if not data.has("version"):
			continue
		var version_value = data["version"]
		var version_type := typeof(version_value)
		if version_type != TYPE_INT and version_type != TYPE_FLOAT:
			return {
				"guarded": true,
				"slot_id": resolved_slot,
				"version": version_value,
				"version_type": version_type,
				"reason": "unknown_version_type",
				"path": path,
			}
		var version := float(version_value)
		if version > SAVE_VERSION:
			return {
				"guarded": true,
				"slot_id": resolved_slot,
				"version": version,
				"version_type": version_type,
				"reason": "future_version",
				"path": path,
			}
	return {
		"guarded": false,
		"slot_id": resolved_slot,
		"version": 0,
		"version_type": TYPE_NIL,
		"reason": "",
		"path": "",
	}


func is_future_save_version_guarded(slot_id: int = -1) -> bool:
	return bool(future_save_guard_status(slot_id).get("guarded", false))


func set_active_save_slot(slot_id: int, load_slot := true) -> bool:
	if not _save_storage_ready:
		_report_save_failure(save_storage_block_message())
		return false
	var resolved_slot := _normalized_slot(slot_id)
	if is_future_save_version_guarded(resolved_slot):
		active_save_slot = resolved_slot
		_reset_runtime_state()
		_remember_current_titles()
		progress_changed.emit()
		return false
	var selection := _select_save_candidate(resolved_slot)
	if bool(selection.get("has_artifact", false)) and not bool(selection.get("found", false)):
		_report_save_failure(INVALID_SAVE_MESSAGE)
		return false
	active_save_slot = resolved_slot
	_ensure_slot_dir(active_save_slot)
	if not load_slot:
		return true
	_reset_runtime_state()
	if has_save_file(active_save_slot):
		load_game()
	else:
		_remember_current_titles()
		progress_changed.emit()
	return true


func save_slot_summary(slot_id: int) -> Dictionary:
	var resolved_slot := _normalized_slot(slot_id)
	if not _save_storage_ready:
		return {
			"slot_id": resolved_slot,
			"active": resolved_slot == active_save_slot,
			"has_save": false,
			"level": 1,
			"money": 500,
			"play_seconds": 0.0,
			"difficulty_id": GameData.DEFAULT_DIFFICULTY_ID,
			"updated_unix": 0,
			"future_guarded": false,
			"future_version": null,
			"storage_blocked": true,
			"storage_block_message": save_storage_block_message(),
		}
	var future_guard := future_save_guard_status(resolved_slot)
	var future_guarded := bool(future_guard.get("guarded", false))
	var selection := _select_save_candidate(resolved_slot)
	var data: Dictionary = selection.get("data", {})
	var invalid_artifact := (
		bool(selection.get("has_artifact", false)) and not bool(selection.get("found", false))
	)
	var updated_unix := 0
	var selected_path := String(selection.get("path", ""))
	if not selected_path.is_empty():
		updated_unix = int(FileAccess.get_modified_time(selected_path))
	var summary_level := 1
	var summary_money := 500
	var summary_play_seconds := 0.0
	var summary_difficulty_id := GameData.DEFAULT_DIFFICULTY_ID
	if not future_guarded:
		summary_level = int(data.get("level", summary_level))
		summary_money = int(data.get("money", summary_money))
		summary_play_seconds = float(data.get("play_seconds", summary_play_seconds))
		summary_difficulty_id = _normalized_difficulty_id(
			data.get("difficulty_id", summary_difficulty_id)
		)
	return {
		"slot_id": resolved_slot,
		"active": resolved_slot == active_save_slot,
		"has_save": bool(selection.get("found", false)) or invalid_artifact,
		"candidate_valid": bool(selection.get("found", false)),
		"invalid_artifact": invalid_artifact,
		"invalid_message": INVALID_SAVE_TITLE_MESSAGE if invalid_artifact else "",
		"level": summary_level,
		"money": summary_money,
		"play_seconds": summary_play_seconds,
		"difficulty_id": summary_difficulty_id,
		"updated_unix": updated_unix,
		"future_guarded": future_guarded,
		"future_version": future_guard.get("version", null),
		"storage_blocked": false,
		"storage_block_message": "",
	}


func difficulty() -> Dictionary:
	var resolved_id := _normalized_difficulty_id(difficulty_id)
	return Dictionary(GameData.DIFFICULTIES[resolved_id]).duplicate(true)


func difficulty_adjusted_exp(amount: int) -> int:
	return _scaled_nonnegative_int(
		amount, float(difficulty().get("exp_multiplier", 1.0))
	)


func cooking_exp_preview(fish_id: String, recipe_id: String) -> Dictionary:
	var raw_base_exp := GameData.recipe_exp(fish_id, recipe_id)
	var dish_key := "%s:%s" % [fish_id, recipe_id]
	var first_time := (
		not eaten_recipes.has(dish_key)
		and _safe_count_dictionary_total(eaten_recipes) < MAX_SAFE_JSON_INTEGER
	)
	var base_exp := difficulty_adjusted_exp(raw_base_exp)
	var total_exp := difficulty_adjusted_exp(raw_base_exp * 2 if first_time else raw_base_exp)
	return {
		"base_exp": base_exp,
		"first_time": first_time,
		"first_bonus": total_exp - base_exp if first_time else 0,
		"total_exp": total_exp,
	}


func reset_game(selected_difficulty_id: String = GameData.DEFAULT_DIFFICULTY_ID) -> bool:
	if not _save_storage_ready:
		_report_save_failure(save_storage_block_message())
		return false
	if is_future_save_version_guarded():
		_report_save_failure(FUTURE_SAVE_GUARD_MESSAGE)
		return false
	if not GameData.DIFFICULTIES.has(selected_difficulty_id):
		_report_save_failure(INVALID_DIFFICULTY_MESSAGE)
		return false
	var selection := _select_save_candidate(active_save_slot)
	if bool(selection.get("has_artifact", false)) and not bool(selection.get("found", false)):
		_report_save_failure(INVALID_SAVE_MESSAGE)
		return false
	_reset_runtime_state()
	difficulty_id = _normalized_difficulty_id(selected_difficulty_id)
	_remember_current_titles()
	var saved := save_game()
	progress_changed.emit()
	return saved


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
	sea_chart_fragments = 0
	shark_bonds = {}
	selected_time_slot_id = GameData.DEFAULT_TIME_SLOT_ID
	difficulty_id = GameData.DEFAULT_DIFFICULTY_ID


func add_sea_chart_fragments(amount: int = 1) -> int:
	var before := sea_chart_fragments
	sea_chart_fragments = clampi(sea_chart_fragments + amount, 0, SEA_CHART_FRAGMENT_MAX)
	return sea_chart_fragments - before


func _saturating_add_nonnegative(current: int, amount: int) -> int:
	var bounded_current := clampi(current, 0, MAX_SAFE_JSON_INTEGER)
	if amount <= 0:
		return bounded_current
	if bounded_current >= MAX_SAFE_JSON_INTEGER or amount >= MAX_SAFE_JSON_INTEGER - bounded_current:
		return MAX_SAFE_JSON_INTEGER
	return bounded_current + amount


func _saturating_multiply_nonnegative(left: int, right: int) -> int:
	if left <= 0 or right <= 0:
		return 0
	if left >= MAX_SAFE_JSON_INTEGER or right >= MAX_SAFE_JSON_INTEGER:
		return MAX_SAFE_JSON_INTEGER
	@warning_ignore("integer_division")
	var largest_safe_left := MAX_SAFE_JSON_INTEGER / right
	if left > largest_safe_left:
		return MAX_SAFE_JSON_INTEGER
	return left * right


func _scaled_nonnegative_int(value: int, multiplier: float) -> int:
	if value <= 0 or multiplier <= 0.0:
		return 0
	var bounded_value := mini(value, MAX_SAFE_JSON_INTEGER)
	if not is_finite(multiplier):
		return MAX_SAFE_JSON_INTEGER
	var scaled_multiplier := multiplier * float(DIFFICULTY_MULTIPLIER_SCALE)
	if scaled_multiplier >= float(MAX_SAFE_JSON_INTEGER):
		return MAX_SAFE_JSON_INTEGER
	var numerator := maxi(0, int(round(scaled_multiplier)))
	return _saturating_multiply_divide_nonnegative(
		bounded_value, numerator, DIFFICULTY_MULTIPLIER_SCALE
	)


func _saturating_multiply_divide_nonnegative(
	value: int, numerator: int, denominator: int
) -> int:
	if value <= 0 or numerator <= 0 or denominator <= 0:
		return 0
	@warning_ignore("integer_division")
	var quotient := value / denominator
	var remainder := value % denominator
	var whole := _saturating_multiply_nonnegative(quotient, numerator)
	var fractional_product := remainder * numerator
	@warning_ignore("integer_division")
	var fractional := fractional_product / denominator
	return _saturating_add_nonnegative(whole, fractional)


func _safe_count_dictionary_total(values: Dictionary) -> int:
	var total := 0
	for value in values.values():
		if not _is_integer_at_least(value, 0):
			return MAX_SAFE_JSON_INTEGER
		total = _saturating_add_nonnegative(total, int(value))
	return total


func _increment_count_with_global_cap(values: Dictionary, key: String) -> bool:
	var current := int(values.get(key, 0))
	if current >= MAX_SAFE_JSON_INTEGER or _safe_count_dictionary_total(values) >= MAX_SAFE_JSON_INTEGER:
		return false
	values[key] = current + 1
	return true


func gain_trip_event_money(amount: int) -> void:
	if amount <= 0:
		return
	money = _saturating_add_nonnegative(money, amount)
	save_game()
	progress_changed.emit()


func gain_trip_event_sea_chart_fragment() -> int:
	var gained := add_sea_chart_fragments(1)
	if gained > 0:
		save_game()
		progress_changed.emit()
	return gained


func exp_to_next_level() -> int:
	if level >= GameData.MAX_LEVEL:
		return 0
	return EXP_REQUIREMENTS[level]


func add_exp(amount: int) -> Array[int]:
	var leveled_to: Array[int] = []
	if amount <= 0 or level >= GameData.MAX_LEVEL:
		return leveled_to

	exp = _saturating_add_nonnegative(exp, amount)
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
		"first_catch": false,
		"boss_first_clear_reward": {},
		"record_broken": previous_count > 0 and size_cm > previous_best,
		"previous_best_cm": previous_best,
		"new_titles": [],
		"sent_to_shark_pen": false,
	}
	var is_shark := bool(fish.get("shark", false))
	if is_shark:
		catch_result["sent_to_shark_pen"] = true
		if GameData.is_raiseable_shark_id(fish_id) and not shark_bonds.has(fish_id):
			shark_bonds[fish_id] = 0
	else:
		_increment_count_with_global_cap(inventory, fish_id)
	var caught_incremented := _increment_count_with_global_cap(caught_counts, fish_id)
	catch_result["first_catch"] = previous_count <= 0 and caught_incremented
	if not spot_id.is_empty():
		var spot_counts: Dictionary = {}
		var loaded_spot_counts = spot_caught_counts.get(spot_id, {})
		if typeof(loaded_spot_counts) == TYPE_DICTIONARY:
			spot_counts = loaded_spot_counts.duplicate(true)
		spot_counts[fish_id] = _saturating_add_nonnegative(
			int(spot_counts.get(fish_id, 0)), 1
		)
		spot_caught_counts[spot_id] = spot_counts
	best_sizes[fish_id] = maxf(float(best_sizes.get(fish_id, 0.0)), size_cm)
	if bool(catch_result["first_catch"]) and bool(fish.get("boss", false)):
		var reward := GameData.get_boss_first_clear_reward(fish_id)
		var reward_money := int(reward.get("money", 0))
		if reward_money > 0:
			money = _saturating_add_nonnegative(money, reward_money)
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
	if fish.is_empty() or bool(fish.get("shark", false)) or amount <= 0 or current < amount:
		return {"ok": false, "message": "売却できる魚が足りません。"}

	var base_income := _saturating_multiply_nonnegative(int(fish["sell_price"]), amount)
	var income := _scaled_nonnegative_int(
		base_income, float(difficulty().get("sell_price_multiplier", 1.0))
	)
	inventory[fish_id] = current - amount
	money = _saturating_add_nonnegative(money, income)
	save_game()
	progress_changed.emit()
	return {"ok": true, "income": income, "amount": amount}


## inventoryを参照しないpure見積。市場表示と実売却で同じ安全な積算結果を共有する。
func quote_fish_sale(orders: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	var sold: Dictionary = {}
	var income := 0
	var total_amount := 0
	var sell_price_multiplier := float(difficulty().get("sell_price_multiplier", 1.0))

	for key in orders.keys():
		var fish_id := String(key)
		var amount := int(orders[key])
		if amount <= 0:
			continue
		var fish := GameData.get_fish(fish_id)
		if fish.is_empty() or bool(fish.get("shark", false)):
			return {
				"ok": false,
				"reason": "invalid_fish",
				"income": 0,
				"amount": 0,
				"total_amount": 0,
				"types": 0,
				"orders": {},
				"sold": {},
			}
		normalized[fish_id] = amount

	for fish_id in normalized.keys():
		var amount := int(normalized[fish_id])
		var fish := GameData.get_fish(fish_id)
		var base_item_income := _saturating_multiply_nonnegative(int(fish["sell_price"]), amount)
		var item_income := _scaled_nonnegative_int(base_item_income, sell_price_multiplier)
		income = _saturating_add_nonnegative(income, item_income)
		total_amount = _saturating_add_nonnegative(total_amount, amount)
		sold[fish_id] = {
			"amount": amount,
			"income": item_income,
		}

	return {
		"ok": not normalized.is_empty(),
		"reason": "" if not normalized.is_empty() else "empty",
		"income": income,
		"amount": total_amount,
		"total_amount": total_amount,
		"types": normalized.size(),
		"orders": normalized,
		"sold": sold,
	}


func sell_fish_batch(orders: Dictionary) -> Dictionary:
	var quote := quote_fish_sale(orders)
	if not bool(quote.get("ok", false)):
		var invalid_fish := String(quote.get("reason", "")) == "invalid_fish"
		return {
			"ok": false,
			"income": 0,
			"total_amount": 0,
			"sold": {},
			"message": (
				"売却できる魚が足りません。"
				if invalid_fish
				else "売る魚を選んでください。"
			),
		}

	var normalized: Dictionary = quote.get("orders", {})
	for fish_id in normalized.keys():
		var amount := int(normalized[fish_id])
		if fish_count(fish_id) < amount:
			return {
				"ok": false,
				"income": 0,
				"total_amount": 0,
				"sold": {},
				"message": "売却できる魚が足りません。",
			}

	for fish_id in normalized.keys():
		inventory[fish_id] = fish_count(fish_id) - int(normalized[fish_id])

	var income := int(quote.get("income", 0))
	var total_amount := int(quote.get("total_amount", 0))
	var sold: Dictionary = Dictionary(quote.get("sold", {})).duplicate(true)
	money = _saturating_add_nonnegative(money, income)
	save_game()
	progress_changed.emit()
	return {
		"ok": true,
		"income": income,
		"total_amount": total_amount,
		"sold": sold,
		"message": "%d匹売って、%d Gを受け取った。" % [total_amount, income],
	}


func feed_shark(shark_id: String, fish_id: String) -> Dictionary:
	if not GameData.is_raiseable_shark_id(shark_id):
		return {"ok": false, "message": "飼育できるサメではありません。"}
	if int(caught_counts.get(shark_id, 0)) <= 0:
		return {"ok": false, "message": "まだこのサメを生簀に迎えていません。"}
	var food := GameData.get_fish(fish_id)
	if food.is_empty():
		return {"ok": false, "message": "餌にする魚データが見つかりません。"}
	if bool(food.get("shark", false)):
		return {"ok": false, "message": "サメは餌にできません。"}
	var current_count := fish_count(fish_id)
	if current_count <= 0:
		return {"ok": false, "message": "餌にする魚を持っていません。"}

	if not shark_bonds.has(shark_id):
		shark_bonds[shark_id] = 0
	var before_bond := clampi(int(shark_bonds.get(shark_id, 0)), 0, 100)
	var favorite := GameData.is_favorite_food(shark_id, food)
	var bond_gain := GameData.SHARK_FAVORITE_BOND_GAIN if favorite else GameData.SHARK_DEFAULT_BOND_GAIN
	var exp_multiplier := (
		GameData.SHARK_FAVORITE_EXP_MULTIPLIER
		if favorite
		else GameData.SHARK_DEFAULT_EXP_MULTIPLIER
	)
	var after_bond := clampi(before_bond + bond_gain, 0, 100)
	var base_exp_gain := int(round(float(food.get("food_exp", 0)) * exp_multiplier))
	var exp_gain := difficulty_adjusted_exp(base_exp_gain)
	inventory[fish_id] = current_count - 1
	shark_bonds[shark_id] = after_bond
	var leveled_to := add_exp(exp_gain)
	var new_titles := _award_new_titles()
	save_game()
	progress_changed.emit()
	return {
		"ok": true,
		"shark_id": shark_id,
		"fish_id": fish_id,
		"favorite": favorite,
		"bond_before": before_bond,
		"bond_after": after_bond,
		"bond_gain": after_bond - before_bond,
		"exp_gain": exp_gain,
		"leveled_to": leveled_to,
		"completed": before_bond < 100 and after_bond >= 100,
		"new_titles": new_titles,
		"message": "サメに餌をあたえた。",
	}


func consume_fish_for_shark_lure(fish_id: String) -> Dictionary:
	var food := GameData.get_fish(fish_id)
	if food.is_empty():
		return {"ok": false, "message": "餌魚にする魚データが見つかりません。"}
	if bool(food.get("shark", false)):
		return {"ok": false, "message": "サメは餌魚にできません。"}
	var current_count := fish_count(fish_id)
	if current_count <= 0:
		return {"ok": false, "message": "餌魚にする魚を持っていません。"}

	inventory[fish_id] = current_count - 1
	save_game()
	progress_changed.emit()
	return {
		"ok": true,
		"fish_id": fish_id,
		"fish_name": String(food.get("name", fish_id)),
		"fish": food.duplicate(true),
		"message": "%sを餌魚にした。" % String(food.get("name", fish_id)),
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
	if GameData.is_quest_excluded_fish_id(fish_id):
		return {"ok": false, "message": "この依頼は現在は受け付けできません。", "progress": progress}
	if kind == "delivery":
		var required_count := int(quest.get("count", 0))
		var current_count := fish_count(fish_id)
		if current_count < required_count:
			return {"ok": false, "message": "納品する魚が足りません。", "progress": progress}
		inventory[fish_id] = current_count - required_count

	var reward := int(quest.get("reward_money", 0))
	money = _saturating_add_nonnegative(money, reward)
	quest_completed_count = _saturating_add_nonnegative(quest_completed_count, 1)
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
	if bool(fish.get("shark", false)):
		return {"ok": false, "message": "サメは生簀で飼育します。"}
	if fish_count(fish_id) <= 0:
		return {"ok": false, "message": "その魚を持っていません。"}
	if level < int(recipe["unlock_level"]):
		return {"ok": false, "message": "まだこの料理は作れません。"}
	if fish_id not in recipe["allowed_fish"]:
		return {"ok": false, "message": "この魚には選んだ調理法を使えません。"}

	inventory[fish_id] = fish_count(fish_id) - 1
	var dish_key := "%s:%s" % [fish_id, recipe_id]
	var exp_preview := cooking_exp_preview(fish_id, recipe_id)
	var base_exp := int(exp_preview.get("base_exp", 0))
	var first_time := bool(exp_preview.get("first_time", false))
	var first_bonus := int(exp_preview.get("first_bonus", 0))
	var total_exp := int(exp_preview.get("total_exp", base_exp))
	var eaten_count_incremented := _increment_count_with_global_cap(eaten_recipes, dish_key)
	if first_time and not eaten_count_incremented:
		first_time = false
		first_bonus = 0
		total_exp = base_exp
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
	return GameData.fishing_spot_access_status(spot_id, level, owned_boats, sea_chart_fragments)


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
	var difficulty_data := difficulty()
	var base_safe_min := maxf(0.10, 0.22 - float(technique_points) * 0.007)
	var base_safe_max := minf(0.88, 0.72 + float(technique_points) * 0.010)
	return {
		"level": level,
		"max_energy": 100.0 + growth * 5.0,
		"reel_power": (5.6 + growth * 0.58) * float(rod.get("reel_multiplier", 1.0)),
		"technique": technique_points,
		"focus": growth_floor,
		"energy_regen": 14.0 + growth * 0.45,
		"bite_window_bonus": growth * 0.025,
		"safe_min": clampf(
			base_safe_min + float(difficulty_data.get("safe_min_shift", 0.0)), 0.06, 0.94
		),
		"safe_max": clampf(
			base_safe_max + float(difficulty_data.get("safe_max_shift", 0.0)), 0.06, 0.94
		),
		"line_break_limit": (
			(1.0 + float(rod.get("line_limit_bonus", 0.0)))
			* float(difficulty_data.get("line_break_multiplier", 1.0))
		),
		"rod_name": String(rod.get("name", "港の入門竿")),
	}


func begin_fishing_trip() -> Dictionary:
	var stats := get_base_stats()
	var environment := GameData.roll_fishing_environment()
	selected_time_slot_id = _normalized_time_slot_id(selected_time_slot_id)
	var time_slot := GameData.get_time_slot(selected_time_slot_id)
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
	stats["time_slot_id"] = selected_time_slot_id
	stats["time_slot_label"] = String(time_slot.get("name", "日中"))
	stats["time_slot_grade"] = String(time_slot.get("grade", "none"))
	var surface_bgm_override := String(time_slot.get("surface_bgm_key_override", ""))
	if not surface_bgm_override.strip_edges().is_empty():
		stats["surface_bgm_key"] = surface_bgm_override
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


func can_select_time_slot(time_slot_id: String) -> bool:
	var time_slot := GameData.get_time_slot(time_slot_id)
	if time_slot.is_empty():
		return false
	return String(time_slot.get("id", GameData.DEFAULT_TIME_SLOT_ID)) == time_slot_id and GameData.is_time_slot_unlocked(time_slot_id, level)


func select_time_slot(time_slot_id: String) -> bool:
	if not can_select_time_slot(time_slot_id):
		return false
	selected_time_slot_id = time_slot_id
	save_game()
	progress_changed.emit()
	return true


func title_stats_snapshot() -> Dictionary:
	return {
		"level": level,
		"caught_counts": caught_counts.duplicate(true),
		"spot_caught_counts": spot_caught_counts.duplicate(true),
		"best_sizes": best_sizes.duplicate(true),
		"eaten_recipes": eaten_recipes.duplicate(true),
		"quest_completed_count": quest_completed_count,
		"shark_bonds": shark_bonds.duplicate(true),
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
		"sea_chart_fragments": sea_chart_fragments,
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


func save_game() -> bool:
	if _sandbox_mode:
		return true
	if not _save_storage_ready:
		_report_save_failure(save_storage_block_message())
		return false
	if is_future_save_version_guarded():
		_report_save_failure(FUTURE_SAVE_GUARD_MESSAGE)
		return false
	var current_selection := _select_save_candidate(active_save_slot)
	if bool(current_selection.get("has_artifact", false)) and not bool(current_selection.get("found", false)):
		_report_save_failure(INVALID_SAVE_MESSAGE)
		return false
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
		"sea_chart_fragments": sea_chart_fragments,
		"shark_bonds": shark_bonds,
		"selected_time_slot_id": selected_time_slot_id,
		"difficulty_id": difficulty_id,
	}
	if not _is_valid_save_candidate(data):
		_report_save_failure(INVALID_OUTBOUND_SAVE_MESSAGE)
		return false
	var save_path := current_save_path()
	var backup_path := current_backup_path()
	var tmp_path := current_tmp_path()
	var preserve_valid_backup := String(current_selection.get("source", "")) == "backup"
	# 一時ファイルへ書き切ってから差し替える（書き込み途中のクラッシュで本体を壊さない）
	var tmp_file: FileAccess = null
	if _save_failure_injection_stage != "tmp_open":
		tmp_file = FileAccess.open(tmp_path, FileAccess.WRITE)
	if tmp_file == null:
		return _fail_save("セーブ用の一時ファイルを開けませんでした。")
	if _save_failure_injection_stage == "write_unavailable":
		tmp_file.close()
		_remove_save_tmp(tmp_path)
		return _fail_save("セーブデータを書き込めませんでした。")
	tmp_file.store_string(JSON.stringify(data, "\t"))
	var write_error := tmp_file.get_error()
	tmp_file.close()
	if write_error != OK:
		_remove_save_tmp(tmp_path)
		return _fail_save("セーブデータを書き込めませんでした（コード: %d）。" % write_error)

	# fallback中は不正mainで唯一の正常backupを上書きしない。final失敗注入は原本へ触る前に返す。
	if preserve_valid_backup and _save_failure_injection_stage == "final_rename":
		_remove_save_tmp(tmp_path)
		return _fail_save("セーブファイルの差し替えに失敗しました（コード: %d）。" % ERR_CANT_CREATE)
	# 直前の正常な本体を1世代バックアップとして残す。
	if FileAccess.file_exists(save_path) and not preserve_valid_backup:
		var backup_err := ERR_CANT_CREATE if _save_failure_injection_stage == "backup_rename" else DirAccess.rename_absolute(save_path, backup_path)
		if backup_err != OK:
			_remove_save_tmp(tmp_path)
			return _fail_save("セーブのバックアップ作成に失敗しました（コード: %d）。" % backup_err)
	if preserve_valid_backup and FileAccess.file_exists(save_path):
		var remove_err := DirAccess.remove_absolute(save_path)
		if remove_err != OK:
			_remove_save_tmp(tmp_path)
			return _fail_save("不正なセーブ本体を安全に差し替えられませんでした（コード: %d）。" % remove_err)
	var fail_final_rename := _save_failure_injection_stage in [
		"final_rename", "fallback_final_rename_after_remove"
	]
	var rename_err := ERR_CANT_CREATE if fail_final_rename else DirAccess.rename_absolute(tmp_path, save_path)
	if rename_err != OK:
		_remove_save_tmp(tmp_path)
		if FileAccess.file_exists(backup_path) and not FileAccess.file_exists(save_path):
			# backup世代を残したままmainを復元し、再試行可能な状態を維持する。
			var restore_err := DirAccess.copy_absolute(backup_path, save_path)
			if restore_err != OK:
				return _fail_save("セーブファイルの差し替えと復元に失敗しました（コード: %d / %d）。" % [rename_err, restore_err])
		return _fail_save("セーブファイルの差し替えに失敗しました（コード: %d）。" % rename_err)
	return true


func _fail_save(message: String) -> bool:
	_report_save_failure(message)
	return false


func _report_save_failure(message: String) -> void:
	push_warning(message)
	save_failed.emit(message)


func _remove_save_tmp(tmp_path: String) -> void:
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)


func load_game() -> void:
	if _sandbox_mode:
		_remember_current_titles()
		return
	if not _save_storage_ready:
		push_warning(save_storage_block_message())
		_remember_current_titles()
		return
	if is_future_save_version_guarded():
		push_warning(FUTURE_SAVE_GUARD_MESSAGE)
		_remember_current_titles()
		return
	var selection := _select_save_candidate(active_save_slot)
	if not bool(selection.get("found", false)):
		if bool(selection.get("has_artifact", false)):
			_report_save_failure(INVALID_SAVE_MESSAGE)
		_remember_current_titles()
		return
	if String(selection.get("source", "")) == "backup":
		push_warning("セーブデータが壊れていたため、バックアップから復元します。")
	var data: Dictionary = selection.get("data", {})
	_apply_save_data(_migrate_save_data(data))
	_remember_current_titles()


func _select_save_candidate(slot_id: int) -> Dictionary:
	var has_artifact := false
	var candidates := [
		{"source": "main", "path": _slot_save_path(slot_id)},
		{"source": "backup", "path": _slot_backup_path(slot_id)},
	]
	for candidate in candidates:
		var path := String(candidate["path"])
		if not FileAccess.file_exists(path):
			continue
		has_artifact = true
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var data := Dictionary(parsed)
		if not _is_valid_save_candidate(data):
			continue
		return {
			"found": true,
			"has_artifact": true,
			"source": String(candidate["source"]),
			"path": path,
			"data": data,
		}
	return {"found": false, "has_artifact": has_artifact, "source": "", "path": "", "data": {}}


func _is_valid_save_candidate(data: Dictionary) -> bool:
	var known_keys := [
		"version", "level", "exp", "money", "inventory", "caught_counts",
		"spot_caught_counts", "best_sizes", "eaten_recipes", "owned_rods",
		"equipped_rod_id", "owned_rigs", "equipped_rig_id", "owned_boats",
		"pending_buff", "play_seconds", "quest_board", "quest_completed_count",
		"sea_chart_fragments", "shark_bonds", "selected_time_slot_id", "difficulty_id",
	]
	var has_known_key := false
	for key in known_keys:
		if data.has(key):
			has_known_key = true
			break
	if not has_known_key:
		return false
	if data.has("version") and not _is_integer_in_range(data["version"], SAVE_VERSION, SAVE_VERSION):
		return false
	for key in ["level"]:
		if data.has(key) and not _is_integer_in_range(data[key], 1, GameData.MAX_LEVEL):
			return false
	for key in ["exp", "money", "quest_completed_count"]:
		if data.has(key) and not _is_integer_at_least(data[key], 0):
			return false
	if data.has("play_seconds") and not _is_number_at_least(data["play_seconds"], 0.0):
		return false
	if data.has("sea_chart_fragments") and not _is_integer_in_range(data["sea_chart_fragments"], 0, SEA_CHART_FRAGMENT_MAX):
		return false
	for key in ["inventory", "caught_counts", "eaten_recipes"]:
		if data.has(key) and not _is_safe_count_dictionary(data[key]):
			return false
	if data.has("best_sizes") and not _is_nonnegative_float_dictionary(data["best_sizes"]):
		return false
	if data.has("spot_caught_counts") and not _is_valid_spot_caught_counts(data["spot_caught_counts"]):
		return false
	if data.has("pending_buff") and typeof(data["pending_buff"]) != TYPE_DICTIONARY:
		return false
	for key in ["owned_rods", "owned_rigs", "owned_boats"]:
		if data.has(key) and not _is_string_array(data[key]):
			return false
	for key in [
		"equipped_rod_id", "equipped_rig_id", "selected_time_slot_id", "difficulty_id"
	]:
		if data.has(key) and typeof(data[key]) != TYPE_STRING:
			return false
	if data.has("quest_board") and not _is_structurally_valid_quest_board(data["quest_board"]):
		return false
	if data.has("shark_bonds"):
		if typeof(data["shark_bonds"]) != TYPE_DICTIONARY:
			return false
		for value in Dictionary(data["shark_bonds"]).values():
			if not _is_integer_at_least(value, 0):
				return false
	return true


func _is_json_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))


func _is_number_at_least(value: Variant, minimum: float) -> bool:
	return _is_json_number(value) and float(value) >= minimum


func _is_number_in_range(value: Variant, minimum: float, maximum: float) -> bool:
	return _is_json_number(value) and float(value) >= minimum and float(value) <= maximum


func _is_json_integer(value: Variant) -> bool:
	return _is_json_number(value) and float(value) == floorf(float(value))


func _is_integer_at_least(value: Variant, minimum: int) -> bool:
	return (
		_is_json_integer(value)
		and float(value) >= minimum
		and float(value) <= MAX_SAFE_JSON_INTEGER
	)


func _is_integer_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	return _is_json_integer(value) and float(value) >= minimum and float(value) <= maximum


func _is_safe_count_dictionary(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var total := 0
	for item in Dictionary(value).values():
		if not _is_integer_at_least(item, 0):
			return false
		var count := int(item)
		if count > MAX_SAFE_JSON_INTEGER - total:
			return false
		total += count
	return true


func _is_nonnegative_float_dictionary(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	for item in Dictionary(value).values():
		if not _is_number_at_least(item, 0.0):
			return false
	return true


func _is_valid_spot_caught_counts(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	for spot_id in Dictionary(value):
		if typeof(spot_id) != TYPE_STRING or String(spot_id).is_empty():
			return false
		var fish_counts = Dictionary(value)[spot_id]
		if typeof(fish_counts) != TYPE_DICTIONARY:
			return false
		for fish_id in Dictionary(fish_counts):
			if typeof(fish_id) != TYPE_STRING or String(fish_id).is_empty():
				return false
			if not _is_integer_at_least(Dictionary(fish_counts)[fish_id], 0):
				return false
	return true


func _is_string_array(value: Variant) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	for item in Array(value):
		if typeof(item) != TYPE_STRING:
			return false
	return true


func _is_structurally_valid_quest_board(value: Variant) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	for item in Array(value):
		if typeof(item) != TYPE_DICTIONARY:
			return false
		var quest := Dictionary(item)
		for key in ["template_id", "kind", "fish_id"]:
			if quest.has(key) and typeof(quest[key]) != TYPE_STRING:
				return false
		for key in ["count", "reward_money"]:
			if quest.has(key) and not _is_integer_at_least(quest[key], 0):
				return false
		for key in ["target_size_cm", "posted_best_cm"]:
			if quest.has(key) and not _is_number_at_least(quest[key], 0.0):
				return false
	return true


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


func _slot_save_paths(slot_id: int) -> Array[String]:
	return [
		_slot_save_path(slot_id),
		_slot_backup_path(slot_id),
		_slot_tmp_path(slot_id),
	]


func _ensure_slot_dir(slot_id: int) -> void:
	var err := DirAccess.make_dir_recursive_absolute(_slot_dir(slot_id))
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_warning("セーブスロットディレクトリを作成できませんでした（code %d）" % err)


func _migrate_save_data(data: Dictionary) -> Dictionary:
	# version > SAVE_VERSION は load_game() より前のguardで遮断する。
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
	var loaded_shark_bonds = data.get("shark_bonds", {})
	inventory = _normalized_count_dictionary(loaded_inventory)
	caught_counts = _normalized_count_dictionary(loaded_caught_counts)
	spot_caught_counts = _normalized_spot_caught_counts(loaded_spot_caught_counts)
	best_sizes = (
		loaded_best_sizes.duplicate(true) if typeof(loaded_best_sizes) == TYPE_DICTIONARY else {}
	)
	eaten_recipes = _normalized_count_dictionary(loaded_eaten_recipes)
	quest_board = _normalized_quest_board(loaded_quest_board)
	quest_completed_count = maxi(0, int(data.get("quest_completed_count", 0)))
	sea_chart_fragments = clampi(int(data.get("sea_chart_fragments", 0)), 0, SEA_CHART_FRAGMENT_MAX)
	shark_bonds = _normalized_shark_bonds(loaded_shark_bonds)
	selected_time_slot_id = _normalized_time_slot_id(data.get("selected_time_slot_id", GameData.DEFAULT_TIME_SLOT_ID))
	difficulty_id = _normalized_difficulty_id(
		data.get("difficulty_id", GameData.DEFAULT_DIFFICULTY_ID)
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
	_repair_loaded_quest_board()
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
		if GameData.is_quest_excluded_fish_id(String(quest.get("fish_id", ""))):
			continue
		normalized.append(quest)
		if normalized.size() >= 3:
			break
	return normalized


func _repair_loaded_quest_board() -> void:
	while quest_board.size() < 3:
		var quest := GameData.generate_quest(_quest_generation_context())
		if quest.is_empty():
			break
		quest_board.append(quest)


func _normalized_count_dictionary(value: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return normalized
	for key in Dictionary(value).keys():
		normalized[key] = int(Dictionary(value)[key])
	return normalized


func _normalized_spot_caught_counts(value: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return normalized
	for spot_id in Dictionary(value).keys():
		normalized[spot_id] = _normalized_count_dictionary(Dictionary(value)[spot_id])
	return normalized


func _normalized_shark_bonds(value: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return normalized
	for key in Dictionary(value).keys():
		var shark_id := String(key)
		if not GameData.is_raiseable_shark_id(shark_id):
			continue
		normalized[shark_id] = clampi(int(Dictionary(value)[key]), 0, 100)
	return normalized


func _normalized_time_slot_id(value: Variant) -> String:
	var time_slot_id := String(value)
	if not GameData.TIME_SLOTS.has(time_slot_id):
		return GameData.DEFAULT_TIME_SLOT_ID
	if not GameData.is_time_slot_unlocked(time_slot_id, level):
		return GameData.DEFAULT_TIME_SLOT_ID
	return time_slot_id


func _normalized_difficulty_id(value: Variant) -> String:
	if typeof(value) != TYPE_STRING:
		return GameData.DEFAULT_DIFFICULTY_ID
	var resolved_id := String(value)
	if not GameData.DIFFICULTIES.has(resolved_id):
		return GameData.DEFAULT_DIFFICULTY_ID
	return resolved_id


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
