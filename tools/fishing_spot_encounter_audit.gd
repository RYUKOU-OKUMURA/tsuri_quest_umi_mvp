extends SceneTree

const GameDataScript = preload("res://src/autoload/game_data.gd")
const SAMPLE_COUNT := 10000
const AUDIT_LEVELS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 30, 33, 38, 50]
const DANGER_REEF_NORMAL_SHARK_IDS: Array[String] = [
	"nekozame",
	"inuzame",
	"dochizame",
	"hoshizame",
	"eporetto",
	"darumazame",
	"fujikujira",
]
const DANGER_REEF_LURE_ONLY_SHARK_IDS: Array[String] = ["shumokuzame", "hohojirozame"]


func _initialize() -> void:
	var game_data := GameDataScript.new()
	var failures: Array[String] = []
	_check_fish_master(game_data, failures)
	_check_spot_master(game_data, failures)
	_check_environment_master(game_data, failures)
	_check_rig_master(game_data, failures)
	_check_area_limited_distribution(game_data, failures)
	_check_completion_routes(game_data, failures)
	_check_level_gates(game_data, failures)
	_check_boat_gates(game_data, failures)
	_check_danger_reef_shark_distribution(game_data, failures)
	_check_expected_rates(game_data, failures)
	_check_rig_encounter_modifiers(game_data, failures)
	_check_environment_encounter_modifiers(game_data, failures)
	_check_boss_challenge_rewards(game_data, failures)
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


func _check_fish_master(game_data: Object, failures: Array[String]) -> void:
	var fish_ids: Array[String] = game_data.get_all_fish_ids()
	if fish_ids.size() != 79:
		failures.append("expected 79 fish, got %d" % fish_ids.size())
	var seen_numbers: Dictionary = {}
	var required_keys: Array[String] = [
		"id",
		"name",
		"rarity",
		"min_level",
		"boss",
		"weight",
		"size_min",
		"size_max",
		"sell_price",
		"food_exp",
		"stamina",
		"power",
		"speed",
		"start_distance",
		"start_depth",
		"color",
		"habitat",
		"behavior",
		"fish_no",
		"preferred_bait",
		"visual_scale",
		"line_anchor_x",
		"line_anchor_y",
		"motion",
		"action_profile",
		"action_messages",
	]
	for fish_id in fish_ids:
		var fish: Dictionary = game_data.get_fish(fish_id)
		for key in required_keys:
			if not fish.has(key):
				failures.append("%s missing fish key %s" % [fish_id, key])
		var fish_no := String(fish.get("fish_no", ""))
		if seen_numbers.has(fish_no):
			failures.append("%s duplicates fish_no %s with %s" % [fish_id, fish_no, String(seen_numbers[fish_no])])
		seen_numbers[fish_no] = fish_id
		if float(fish.get("size_min", 0.0)) >= float(fish.get("size_max", 0.0)):
			failures.append("%s size_min must be below size_max" % fish_id)
		if float(fish.get("weight", 0.0)) <= 0.0:
			failures.append("%s weight must be positive" % fish_id)


func _check_spot_master(game_data: Object, failures: Array[String]) -> void:
	var spot_ids: Array[String] = game_data.get_all_fishing_spot_ids()
	if spot_ids.size() != 9:
		failures.append("expected 9 fishing spots, got %d" % spot_ids.size())
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


func _check_area_limited_distribution(game_data: Object, failures: Array[String]) -> void:
	var common_fish: Array = game_data.COMMON_LOW_LEVEL_FISH_IDS
	var normal_spots: Array = game_data.NORMAL_FISHING_SPOT_IDS
	var normal_presence: Dictionary = {}
	for spot_id in normal_spots:
		var spot: Dictionary = game_data.get_fishing_spot(String(spot_id))
		var allowed: Array = spot.get("allowed_fish", [])
		for common_id in common_fish:
			if not allowed.has(common_id):
				failures.append("%s missing common fish %s" % [spot_id, common_id])
		var local_count := 0
		for fish_id_variant in allowed:
			var fish_id := String(fish_id_variant)
			if fish_id in common_fish:
				continue
			local_count += 1
			if not normal_presence.has(fish_id):
				normal_presence[fish_id] = []
			normal_presence[fish_id].append(String(spot_id))
		if local_count < 8 or local_count > 9:
			failures.append("%s should have 8-9 local fish, got %d" % [spot_id, local_count])
	for fish_id in game_data.get_all_fish_ids():
		var fish: Dictionary = game_data.get_fish(fish_id)
		if bool(fish.get("boss", false)):
			continue
		if bool(fish.get("shark", false)):
			continue
		if fish_id in common_fish:
			continue
		var spots: Array = normal_presence.get(fish_id, [])
		if spots.size() != 1:
			failures.append("%s should be area-limited to exactly one normal spot, got %s" % [fish_id, ", ".join(PackedStringArray(spots))])


func _check_completion_routes(game_data: Object, failures: Array[String]) -> void:
	for fish_id in game_data.get_all_fish_ids():
		var fish: Dictionary = game_data.get_fish(fish_id)
		if int(fish.get("sell_price", 0)) <= 0:
			failures.append("%s sell_price must be positive" % fish_id)
		if game_data.get_recipes_for_fish(fish_id, game_data.MAX_LEVEL).is_empty():
			failures.append("%s must be cookable by at least one recipe" % fish_id)
		if bool(fish.get("shark", false)):
			if fish_id in DANGER_REEF_LURE_ONLY_SHARK_IDS:
				continue
			var danger_weights: Dictionary = game_data.encounter_weights(game_data.MAX_LEVEL, "danger_reef")
			if not danger_weights.has(fish_id) or float(danger_weights[fish_id]) <= 0.0:
				failures.append("%s shark must be reachable in danger_reef at Lv.%d" % [fish_id, game_data.MAX_LEVEL])
			continue
		if bool(fish.get("boss", false)):
			var boss_spot: Dictionary = game_data.get_fishing_spot(game_data.BOSS_FISHING_SPOT_ID)
			if not Array(boss_spot.get("allowed_fish", [])).has(fish_id):
				failures.append("%s boss fish is not reachable from boss spot" % fish_id)
			continue
		var reachable := false
		for spot_id in game_data.NORMAL_FISHING_SPOT_IDS:
			var weights: Dictionary = game_data.encounter_weights(game_data.MAX_LEVEL, String(spot_id))
			if weights.has(fish_id) and float(weights[fish_id]) > 0.0:
				reachable = true
				break
		if not reachable:
			failures.append("%s must be reachable in at least one normal spot at Lv.%d" % [fish_id, game_data.MAX_LEVEL])


func _check_environment_master(game_data: Object, failures: Array[String]) -> void:
	var environment_ids: Array[String] = game_data.get_all_fishing_environment_ids()
	if environment_ids.size() < 5:
		failures.append("expected at least 5 fishing environments, got %d" % environment_ids.size())
	if not environment_ids.has(game_data.DEFAULT_FISHING_ENVIRONMENT_ID):
		failures.append("environment list missing default %s" % game_data.DEFAULT_FISHING_ENVIRONMENT_ID)
	var weather_ids: Array[String] = []
	var total_weight := 0.0
	for environment_id in environment_ids:
		var environment: Dictionary = game_data.get_fishing_environment(environment_id)
		for key in ["id", "weather_id", "weather_label", "wind_id", "wind_label", "surface_bgm_key", "weight", "fish_weight_modifiers"]:
			if not environment.has(key):
				failures.append("%s missing environment key %s" % [environment_id, key])
		var weather_id := String(environment.get("weather_id", ""))
		if weather_id.is_empty():
			failures.append("%s weather_id must not be empty" % environment_id)
		elif weather_id not in weather_ids:
			weather_ids.append(weather_id)
		var weight := float(environment.get("weight", 0.0))
		if weight <= 0.0:
			failures.append("%s environment weight must be positive" % environment_id)
		total_weight += maxf(0.0, weight)
		var modifiers: Dictionary = environment.get("fish_weight_modifiers", {})
		for fish_id_variant in modifiers.keys():
			var fish_id := String(fish_id_variant)
			if game_data.get_fish(fish_id).is_empty():
				failures.append("%s modifies unknown fish %s" % [environment_id, fish_id])
				continue
			var modifier := float(modifiers[fish_id])
			if modifier <= 0.0 or modifier > 1.8:
				failures.append("%s fish=%s environment modifier %.2f outside 0..1.8" % [environment_id, fish_id, modifier])
	if weather_ids.size() != 5:
		failures.append("expected 5 weather ids, got %d: %s" % [weather_ids.size(), ", ".join(PackedStringArray(weather_ids))])
	if total_weight <= 0.0:
		failures.append("environment total weight must be positive")


func _check_rig_master(game_data: Object, failures: Array[String]) -> void:
	var rig_ids: Array[String] = game_data.get_all_rig_ids()
	if rig_ids.size() != 7:
		failures.append("expected 7 rigs, got %d" % rig_ids.size())
	if not rig_ids.has(game_data.DEFAULT_RIG_ID):
		failures.append("rig list missing default rig %s" % game_data.DEFAULT_RIG_ID)
	var covered_baits: Array[String] = []
	for rig_id in rig_ids:
		var rig: Dictionary = game_data.get_rig(rig_id)
		for key in ["id", "name", "price", "bait_types", "unlock_level", "description"]:
			if not rig.has(key):
				failures.append("%s missing rig key %s" % [rig_id, key])
		if Array(rig.get("bait_types", [])).is_empty():
			failures.append("%s must support at least one bait type" % rig_id)
		for bait_variant in Array(rig.get("bait_types", [])):
			var bait := String(bait_variant)
			if bait not in covered_baits:
				covered_baits.append(bait)
	for fish_id in game_data.get_all_fish_ids():
		var fish: Dictionary = game_data.get_fish(fish_id)
		var preferred_bait := String(fish.get("preferred_bait", ""))
		if preferred_bait not in covered_baits:
			failures.append("%s preferred bait is not covered by any rig: %s" % [fish_id, preferred_bait])


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
	if game_data.is_fishing_spot_accessible("danger_reef", 29, bluewater_boat, 3):
		failures.append("danger_reef should require Lv.30")
	if game_data.is_fishing_spot_accessible("danger_reef", 30, offshore_boat, 3):
		failures.append("danger_reef should require bluewater boat")
	if game_data.is_fishing_spot_accessible("danger_reef", 30, bluewater_boat, 2):
		failures.append("danger_reef should require completed sea chart")
	if not game_data.is_fishing_spot_accessible("danger_reef", 30, bluewater_boat, 3):
		failures.append("danger_reef should unlock with Lv.30, bluewater boat, and sea chart 3/3")


func _check_danger_reef_shark_distribution(game_data: Object, failures: Array[String]) -> void:
	var weights: Dictionary = game_data.encounter_weights(game_data.MAX_LEVEL, "danger_reef")
	for fish_id in DANGER_REEF_NORMAL_SHARK_IDS:
		if not weights.has(fish_id) or float(weights[fish_id]) <= 0.0:
			failures.append("danger_reef should include normal shark %s" % fish_id)
	for fish_id in DANGER_REEF_LURE_ONLY_SHARK_IDS:
		if weights.has(fish_id) and float(weights[fish_id]) > 0.0:
			failures.append("danger_reef should not include lure-only shark without E10 bait: %s" % fish_id)
	var shark_weight := 0.0
	var total := _total_weight(weights)
	for fish_id in DANGER_REEF_NORMAL_SHARK_IDS:
		shark_weight += float(weights.get(fish_id, 0.0))
	if total <= 0.0 or shark_weight / total < 0.25:
		failures.append("danger_reef normal shark share should be meaningful")


func _check_expected_rates(game_data: Object, failures: Array[String]) -> void:
	for spot_id in game_data.get_all_fishing_spot_ids():
		var spot: Dictionary = game_data.get_fishing_spot(spot_id)
		if int(spot.get("unlock_level", 1)) > 10:
			continue
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


func _check_rig_encounter_modifiers(game_data: Object, failures: Array[String]) -> void:
	for spot_id in game_data.get_all_fishing_spot_ids():
		var spot: Dictionary = game_data.get_fishing_spot(spot_id)
		var audit_level := maxi(10, int(spot.get("unlock_level", 1)))
		var baseline: Dictionary = game_data.encounter_weights(audit_level, spot_id)
		if bool(spot.get("boss_spot", false)):
			for rig_id in game_data.get_all_rig_ids():
				var boss_weights: Dictionary = game_data.encounter_weights(audit_level, spot_id, rig_id)
				if not _weights_equal(baseline, boss_weights):
					failures.append("%s boss spot should ignore rig modifier for %s" % [spot_id, rig_id])
			continue
		for rig_id in game_data.get_all_rig_ids():
			var rig_weights: Dictionary = game_data.encounter_weights(audit_level, spot_id, rig_id)
			if rig_weights.is_empty():
				failures.append("%s rig=%s has no encounter weights" % [spot_id, rig_id])
				continue
			for fish_id_variant in baseline.keys():
				var fish_id := String(fish_id_variant)
				var fish: Dictionary = game_data.get_fish(fish_id)
				var expected_multiplier: float = (
					game_data.RIG_MATCH_WEIGHT_MULTIPLIER
					if game_data.rig_supports_bait(rig_id, String(fish.get("preferred_bait", "")))
					else game_data.RIG_MISMATCH_WEIGHT_MULTIPLIER
				)
				var expected: float = float(baseline[fish_id]) * expected_multiplier
				var actual := float(rig_weights.get(fish_id, -1.0))
				if not _nearly_equal(actual, expected):
					failures.append(
						"%s rig=%s fish=%s expected %.3f got %.3f"
						% [spot_id, rig_id, fish_id, expected, actual]
					)


func _check_environment_encounter_modifiers(game_data: Object, failures: Array[String]) -> void:
	for spot_id in game_data.get_all_fishing_spot_ids():
		var spot: Dictionary = game_data.get_fishing_spot(spot_id)
		var audit_level := maxi(10, int(spot.get("unlock_level", 1)))
		var baseline: Dictionary = game_data.encounter_weights(audit_level, spot_id)
		for environment_id in game_data.get_all_fishing_environment_ids():
			var environment_weights: Dictionary = game_data.encounter_weights(audit_level, spot_id, "", environment_id)
			if bool(spot.get("boss_spot", false)):
				if not _weights_equal(baseline, environment_weights):
					failures.append("%s boss spot should ignore environment modifier for %s" % [spot_id, environment_id])
				continue
			if environment_weights.is_empty():
				failures.append("%s environment=%s has no encounter weights" % [spot_id, environment_id])
				continue
			for fish_id_variant in baseline.keys():
				var fish_id := String(fish_id_variant)
				var expected := float(baseline[fish_id]) * float(game_data.fishing_environment_fish_modifier(environment_id, fish_id))
				var actual := float(environment_weights.get(fish_id, -1.0))
				if not _nearly_equal(actual, expected):
					failures.append(
						"%s environment=%s fish=%s expected %.3f got %.3f"
						% [spot_id, environment_id, fish_id, expected, actual]
					)


func _check_boss_challenge_rewards(game_data: Object, failures: Array[String]) -> void:
	for spot_id in game_data.get_all_fishing_spot_ids():
		var spot: Dictionary = game_data.get_fishing_spot(spot_id)
		if not bool(spot.get("boss_spot", false)):
			continue
		var allowed_fish: Array = spot.get("allowed_fish", [])
		if allowed_fish.size() != 1:
			failures.append("%s boss spot should allow exactly one boss fish" % spot_id)
			continue
		var fish_id := String(allowed_fish[0])
		var fish: Dictionary = game_data.get_fish(fish_id)
		if not bool(fish.get("boss", false)):
			failures.append("%s boss spot target is not flagged as boss: %s" % [spot_id, fish_id])
		var first_clear_reward: Dictionary = game_data.get_boss_first_clear_reward(fish_id)
		if first_clear_reward.is_empty():
			failures.append("%s boss target %s missing first-clear reward" % [spot_id, fish_id])
		elif int(first_clear_reward.get("money", 0)) <= 0:
			failures.append("%s boss target %s first-clear money must be positive" % [spot_id, fish_id])


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


func _weights_equal(left: Dictionary, right: Dictionary) -> bool:
	if left.size() != right.size():
		return false
	for key in left.keys():
		if not right.has(key):
			return false
		if not _nearly_equal(float(left[key]), float(right[key])):
			return false
	return true


func _nearly_equal(left: float, right: float) -> bool:
	return absf(left - right) <= maxf(0.001, absf(right) * 0.001)
