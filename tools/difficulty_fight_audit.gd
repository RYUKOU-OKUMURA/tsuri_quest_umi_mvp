extends Node

const AuditTablePrinter = preload("res://tools/audit_table_printer.gd")
const FishingScreenScript = preload("res://src/ui/fishing_screen.gd")
const FishingSimulatorScript = preload("res://src/core/fishing_simulator.gd")

const EXPECTED_VALUES: Dictionary = {
	"easy": {
		"safe_min": 0.18,
		"safe_max": 0.77,
		"line_break_limit": 1.15,
		"fish_stamina": 35.7,
		"single_income": 90,
		"batch_income": 180,
		"cooking_base_exp": 20,
		"cooking_bonus_exp": 20,
		"cooking_exp": 40,
		"shark_feed_exp": 36,
	},
	"normal": {
		"safe_min": 0.22,
		"safe_max": 0.72,
		"line_break_limit": 1.0,
		"fish_stamina": 42.0,
		"single_income": 90,
		"batch_income": 180,
		"cooking_base_exp": 20,
		"cooking_bonus_exp": 20,
		"cooking_exp": 40,
		"shark_feed_exp": 36,
	},
	"hard": {
		"safe_min": 0.24,
		"safe_max": 0.68,
		"line_break_limit": 0.95,
		"fish_stamina": 52.5,
		"single_income": 112,
		"batch_income": 225,
		"cooking_base_exp": 25,
		"cooking_bonus_exp": 25,
		"cooking_exp": 50,
		"shark_feed_exp": 45,
	},
}

var _failed := false


func _ready() -> void:
	_expect(PlayerProgress.is_sandbox_mode(), "difficulty audit should run in sandbox mode")
	_verify_catalog_contract()
	var rows: Array[Array] = []
	for difficulty_id in GameData.DIFFICULTY_ORDER:
		var actual := _effective_values(difficulty_id)
		_verify_effective_values(difficulty_id, actual)
		rows.append(
			[
				difficulty_id,
				actual["safe_min"],
				actual["safe_max"],
				float(actual["safe_max"]) - float(actual["safe_min"]),
				actual["line_break_limit"],
				actual["fish_stamina"],
				actual["single_income"],
				actual["batch_income"],
				actual["cooking_base_exp"],
				actual["cooking_bonus_exp"],
				actual["cooking_exp"],
				actual["shark_feed_exp"],
			]
		)
	AuditTablePrinter.print_table(
		"difficulty_fight_audit: effective E7 values",
		[
			"Difficulty",
			"SafeMin",
			"SafeMax",
			"SafeWidth",
			"LineLimit",
			"AjiStamina",
			"Iwashi1G",
			"Iwashi2G",
			"CookBase",
			"CookBonus",
			"CookEXP",
			"SharkEXP",
		],
		rows
	)

	if _failed:
		get_tree().quit(1)
		return
	print("difficulty_fight_audit: ok")
	get_tree().quit(0)


func _verify_catalog_contract() -> void:
	_expect_eq(GameData.DEFAULT_DIFFICULTY_ID, "normal", "default difficulty")
	_expect_eq(GameData.DIFFICULTY_ORDER, ["easy", "normal", "hard"], "difficulty order")
	_expect_eq(GameData.DIFFICULTIES.size(), 3, "difficulty count")
	for difficulty_id in GameData.DIFFICULTY_ORDER:
		_expect(GameData.DIFFICULTIES.has(difficulty_id), "%s table entry" % difficulty_id)
		var entry: Dictionary = GameData.DIFFICULTIES[difficulty_id]
		_expect_eq(String(entry.get("id", "")), difficulty_id, "%s entry id" % difficulty_id)
		for key in [
			"name",
			"safe_min_shift",
			"safe_max_shift",
			"line_break_multiplier",
			"fish_stamina_multiplier",
			"sell_price_multiplier",
			"exp_multiplier",
		]:
			_expect(entry.has(key), "%s should define %s" % [difficulty_id, key])
	PlayerProgress.difficulty_id = "unknown"
	_expect_eq(
		String(PlayerProgress.difficulty().get("id", "")),
		GameData.DEFAULT_DIFFICULTY_ID,
		"unknown difficulty should fall back to normal"
	)
	PlayerProgress.difficulty_id = "hard"
	var saturated_quote := PlayerProgress.quote_fish_sale(
		{"iwashi": PlayerProgress.MAX_SAFE_JSON_INTEGER}
	)
	_expect_eq(
		int(saturated_quote.get("income", -1)),
		PlayerProgress.MAX_SAFE_JSON_INTEGER,
		"hard sell multiplier should saturate at the JSON safe integer limit"
	)
	var boundary_value := 7205759403792787
	_expect_eq(
		PlayerProgress._scaled_nonnegative_int(boundary_value, 1.25),
		9007199254740983,
		"hard multiplier should stay exact immediately below saturation"
	)


func _effective_values(selected_difficulty_id: String) -> Dictionary:
	PlayerProgress._reset_runtime_state()
	PlayerProgress.difficulty_id = selected_difficulty_id
	PlayerProgress.level = 1
	PlayerProgress.equipped_rod_id = "starter"
	var stats := PlayerProgress.get_base_stats()
	var aji := GameData.get_fish("aji")
	var original_aji := aji.duplicate(true)
	var fishing_screen = FishingScreenScript.new()
	fishing_screen._simulator = FishingSimulatorScript.new()
	fishing_screen._current_fish = aji
	fishing_screen._trip_stats = stats
	fishing_screen._prepare_current_fish_in_simulator()
	var fish_stamina: float = fishing_screen._simulator.fish_stamina_max
	_expect_eq(aji, original_aji, "%s source fish after prepare" % selected_difficulty_id)
	_expect_eq(
		fishing_screen._current_fish,
		original_aji,
		"%s current fish after prepare" % selected_difficulty_id
	)
	fishing_screen._prepare_current_fish_in_simulator()
	_expect_approx(
		fishing_screen._simulator.fish_stamina_max,
		fish_stamina,
		"%s repeated prepare should not compound stamina" % selected_difficulty_id
	)
	fishing_screen.free()
	var single_quote := PlayerProgress.quote_fish_sale({"iwashi": 1})
	var batch_quote := PlayerProgress.quote_fish_sale({"iwashi": 2})
	PlayerProgress.inventory = {"iwashi": 3}
	PlayerProgress.money = 0
	var single_result := PlayerProgress.sell_fish("iwashi", 1)
	var batch_result := PlayerProgress.sell_fish_batch({"iwashi": 2})
	_expect_eq(
		int(single_result.get("income", -1)),
		int(single_quote.get("income", -1)),
		"%s single quote/actual income" % selected_difficulty_id
	)
	_expect_eq(
		int(batch_result.get("income", -1)),
		int(batch_quote.get("income", -1)),
		"%s batch quote/actual income" % selected_difficulty_id
	)
	_expect_eq(PlayerProgress.fish_count("iwashi"), 0, "%s sold inventory" % selected_difficulty_id)
	_expect_eq(
		PlayerProgress.money,
		int(single_quote.get("income", 0)) + int(batch_quote.get("income", 0)),
		"%s sold money" % selected_difficulty_id
	)

	PlayerProgress.inventory = {"aji": 1}
	PlayerProgress.eaten_recipes = {}
	PlayerProgress.exp = 0
	var cooking_preview := PlayerProgress.cooking_exp_preview("aji", "salt_grill")
	var cooking_result := PlayerProgress.cook_and_eat("aji", "salt_grill")
	for key in ["base_exp", "first_time", "first_bonus", "total_exp"]:
		_expect_eq(
			cooking_result.get(key),
			cooking_preview.get(key),
			"%s cooking preview/actual %s" % [selected_difficulty_id, key]
		)

	PlayerProgress._reset_runtime_state()
	PlayerProgress.difficulty_id = selected_difficulty_id
	PlayerProgress.caught_counts = {"nekozame": 1}
	PlayerProgress.shark_bonds = {"nekozame": 0}
	PlayerProgress.inventory = {"mahaze": 1}
	var feed_result := PlayerProgress.feed_shark("nekozame", "mahaze")

	return {
		"safe_min": float(stats.get("safe_min", 0.0)),
		"safe_max": float(stats.get("safe_max", 0.0)),
		"line_break_limit": float(stats.get("line_break_limit", 0.0)),
		"fish_stamina": fish_stamina,
		"single_income": int(single_result.get("income", -1)),
		"batch_income": int(batch_result.get("income", -1)),
		"cooking_base_exp": int(cooking_result.get("base_exp", -1)),
		"cooking_bonus_exp": int(cooking_result.get("first_bonus", -1)),
		"cooking_exp": int(cooking_result.get("total_exp", -1)),
		"shark_feed_exp": int(feed_result.get("exp_gain", -1)),
	}


func _verify_effective_values(selected_difficulty_id: String, actual: Dictionary) -> void:
	var expected: Dictionary = EXPECTED_VALUES[selected_difficulty_id]
	for key in ["safe_min", "safe_max", "line_break_limit", "fish_stamina"]:
		_expect_approx(
			float(actual.get(key, 0.0)),
			float(expected[key]),
			"%s %s" % [selected_difficulty_id, key]
		)
	for key in [
		"single_income",
		"batch_income",
		"cooking_base_exp",
		"cooking_bonus_exp",
		"cooking_exp",
		"shark_feed_exp",
	]:
		_expect_eq(
			int(actual.get(key, -1)),
			int(expected[key]),
			"%s %s" % [selected_difficulty_id, key]
		)


func _expect_approx(actual: float, expected: float, message: String) -> void:
	_expect(
		is_equal_approx(actual, expected),
		"%s got=%.6f expected=%.6f" % [message, actual, expected]
	)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s got=%s expected=%s" % [message, str(actual), str(expected)])


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
