extends SceneTree

const GameDataScript = preload("res://src/autoload/game_data.gd")
const SAMPLE_COUNT := 10000
const AUDIT_LEVELS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]


func _initialize() -> void:
	var game_data := GameDataScript.new()
	var failures: Array[String] = []
	_check_spot_master(game_data, failures)
	_check_level_gates(game_data, failures)
	_check_boat_gates(game_data, failures)
	_check_expected_rates(game_data, failures)
	_print_sample_summary(game_data)
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		game_data.free()
		quit(1)
		return
	print("fishing_spot_encounter_audit: ok")
	game_data.free()
	quit(0)


func _check_spot_master(game_data: Object, failures: Array[String]) -> void:
	var spot_ids: Array[String] = game_data.get_all_fishing_spot_ids()
	if spot_ids.size() != 8:
		failures.append("expected 8 fishing spots, got %d" % spot_ids.size())
	var required_keys: Array[String] = [
		"id",
		"name",
		"unlock_level",
		"required_boat_rank",
		"depth_range",
		"description",
		"common_modifier",
		"featured_fish",
		"recommended_baits",
		"boss_spot",
		"allowed_fish",
		"fish_weight_modifiers",
	]
	for spot_id in spot_ids:
		var spot: Dictionary = game_data.get_fishing_spot(spot_id)
		for key in required_keys:
			if not spot.has(key):
				failures.append("%s missing spot key %s" % [spot_id, key])
		for featured_fish_id in Array(spot.get("featured_fish", [])):
			if game_data.get_fish(String(featured_fish_id)).is_empty():
				failures.append("%s featured unknown fish %s" % [spot_id, featured_fish_id])
		for allowed_fish_id in Array(spot.get("allowed_fish", [])):
			if game_data.get_fish(String(allowed_fish_id)).is_empty():
				failures.append("%s allows unknown fish %s" % [spot_id, allowed_fish_id])
		var required_boat_rank := int(spot.get("required_boat_rank", 0))
		if required_boat_rank < 0:
			failures.append("%s has negative required_boat_rank" % spot_id)
		if required_boat_rank > 0 and game_data.get_required_boat_for_rank(required_boat_rank).is_empty():
			failures.append("%s requires missing boat rank %d" % [spot_id, required_boat_rank])


func _check_level_gates(game_data: Object, failures: Array[String]) -> void:
	for level in AUDIT_LEVELS:
		for spot_id in game_data.get_all_fishing_spot_ids():
			var spot: Dictionary = game_data.get_fishing_spot(spot_id)
			var unlocked: bool = int(spot.get("unlock_level", 1)) <= level
			var listed_unlocked: bool = game_data.get_unlocked_fishing_spot_ids(level).has(spot_id)
			if unlocked != listed_unlocked:
				failures.append("unlock list mismatch level=%d spot=%s" % [level, spot_id])
			var weights: Dictionary = game_data.encounter_weights(level, spot_id)
			for fish_id_variant in weights.keys():
				var fish_id := String(fish_id_variant)
				var fish: Dictionary = game_data.get_fish(fish_id)
				if bool(fish.get("boss", false)):
					failures.append("boss fish in normal weights level=%d spot=%s fish=%s" % [level, spot_id, fish_id])
				if int(fish.get("min_level", 1)) > level:
					failures.append("locked fish in weights level=%d spot=%s fish=%s" % [level, spot_id, fish_id])


func _check_boat_gates(game_data: Object, failures: Array[String]) -> void:
	var no_boats: Array[String] = []
	var skiff: Array[String] = ["skiff"]
	var offshore_boat: Array[String] = ["offshore_boat"]
	var bluewater_boat: Array[String] = ["bluewater_boat"]
	if game_data.is_fishing_spot_accessible("south_reef", 5, no_boats):
		failures.append("south_reef should require a boat at Lv.5")
	if not game_data.is_fishing_spot_accessible("south_reef", 5, skiff):
		failures.append("south_reef should be accessible with skiff at Lv.5")
	if game_data.is_fishing_spot_accessible("bluewater_route", 6, skiff):
		failures.append("bluewater_route should require offshore boat at Lv.6")
	if not game_data.is_fishing_spot_accessible("bluewater_route", 6, offshore_boat):
		failures.append("bluewater_route should be accessible with offshore boat at Lv.6")
	if game_data.is_fishing_spot_accessible("deep_ocean", 9, offshore_boat):
		failures.append("deep_ocean should require bluewater boat at Lv.9")
	if not game_data.is_fishing_spot_accessible("deep_ocean", 9, bluewater_boat):
		failures.append("deep_ocean should be accessible with bluewater boat at Lv.9")
	if game_data.is_fishing_spot_accessible("south_reef", 4, bluewater_boat):
		failures.append("level gate should still block south_reef before Lv.5")
	if not game_data.is_fishing_spot_accessible("harbor_boulder", 5, no_boats):
		failures.append("boss spot should not require a boat at Lv.5")


func _check_expected_rates(game_data: Object, failures: Array[String]) -> void:
	for spot_id in game_data.get_all_fishing_spot_ids():
		var spot: Dictionary = game_data.get_fishing_spot(spot_id)
		if bool(spot.get("boss_spot", false)):
			var boss_weights: Dictionary = game_data.encounter_weights(10, spot_id)
			if boss_weights.has("boss_kurodai"):
				failures.append("boss spot leaked boss into normal encounter weights")
			continue
		var weights: Dictionary = game_data.encounter_weights(10, spot_id)
		var total: float = _total_weight(weights)
		if total <= 0.0:
			failures.append("%s has no normal encounter weights at Lv.10" % spot_id)
			continue
		var low_share: float = _low_level_share(game_data, weights, total)
		if low_share < 0.40:
			failures.append("%s low-level fish share %.1f%% is below 40%%" % [spot_id, low_share * 100.0])
		for fish_id_variant in weights.keys():
			var fish_id := String(fish_id_variant)
			var fish: Dictionary = game_data.get_fish(fish_id)
			var min_level: int = int(fish.get("min_level", 1))
			var share: float = float(weights[fish_id]) / total
			if min_level >= 9 and share > 0.05:
				failures.append("%s endgame fish %s share %.1f%% exceeds 5%%" % [spot_id, fish_id, share * 100.0])
			elif min_level >= 8 and share > 0.08:
				failures.append("%s large rare fish %s share %.1f%% exceeds 8%%" % [spot_id, fish_id, share * 100.0])
			elif min_level >= 6 and share > 0.10:
				failures.append("%s bluewater fish %s share %.1f%% exceeds 10%%" % [spot_id, fish_id, share * 100.0])
			elif min_level >= 4 and share > 0.14:
				failures.append("%s rare fish %s share %.1f%% exceeds 14%%" % [spot_id, fish_id, share * 100.0])


func _print_sample_summary(game_data: Object) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260630
	print("fishing spot encounter expected/sample summary")
	for level in [1, 3, 5, 7, 10]:
		print("-- Lv.%d --" % level)
		for spot_id in game_data.get_unlocked_fishing_spot_ids(level):
			var spot: Dictionary = game_data.get_fishing_spot(spot_id)
			if bool(spot.get("boss_spot", false)):
				print("%s: boss-only %s" % [spot_id, String(spot.get("name", spot_id))])
				continue
			var weights: Dictionary = game_data.encounter_weights(level, spot_id)
			var counts: Dictionary = _sample_counts(weights, rng)
			print("%s: %s" % [spot_id, _top_entries_text(game_data, weights, counts)])


func _sample_counts(weights: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var counts: Dictionary = {}
	var ids: Array[String] = []
	var total: float = 0.0
	for fish_id_variant in weights.keys():
		var fish_id := String(fish_id_variant)
		ids.append(fish_id)
		counts[fish_id] = 0
		total += float(weights[fish_id])
	if total <= 0.0:
		return counts
	for _index in range(SAMPLE_COUNT):
		var pick: float = rng.randf_range(0.0, total)
		var running: float = 0.0
		for fish_id in ids:
			running += float(weights[fish_id])
			if pick <= running:
				counts[fish_id] = int(counts[fish_id]) + 1
				break
	return counts


func _top_entries_text(game_data: Object, weights: Dictionary, counts: Dictionary) -> String:
	var ids: Array[String] = []
	for fish_id_variant in weights.keys():
		ids.append(String(fish_id_variant))
	ids.sort_custom(func(a: String, b: String) -> bool: return float(weights[a]) > float(weights[b]))
	var total: float = _total_weight(weights)
	var parts: Array[String] = []
	for index in range(mini(5, ids.size())):
		var fish_id := ids[index]
		var fish: Dictionary = game_data.get_fish(fish_id)
		var expected: float = float(weights[fish_id]) / total * 100.0
		var sampled: float = float(counts.get(fish_id, 0)) / float(SAMPLE_COUNT) * 100.0
		parts.append("%s %.1f%%/%.1f%%" % [String(fish.get("name", fish_id)), expected, sampled])
	return " / ".join(parts)


func _total_weight(weights: Dictionary) -> float:
	var total: float = 0.0
	for weight in weights.values():
		total += float(weight)
	return total


func _low_level_share(game_data: Object, weights: Dictionary, total: float) -> float:
	var low_weight: float = 0.0
	for fish_id_variant in weights.keys():
		var fish_id := String(fish_id_variant)
		var fish: Dictionary = game_data.get_fish(fish_id)
		if int(fish.get("min_level", 1)) <= 2:
			low_weight += float(weights[fish_id])
	return low_weight / total
