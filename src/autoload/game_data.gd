extends Node

const FishExpansionData = preload("res://src/autoload/fish_expansion_data.gd")
const GameCatalogData = preload("res://src/autoload/game_catalog_data.gd")

const MAX_LEVEL: int = 50
const BOSS_UNLOCK_LEVEL: int = 5
const DEFAULT_FISHING_SPOT_ID := "harbor_pier"
const BOSS_FISHING_SPOT_ID := "harbor_boulder"
const NO_BOAT_RANK := 0
const DEFAULT_RIG_ID := "sabiki"
const RIG_MATCH_WEIGHT_MULTIPLIER := 2.5
const RIG_MISMATCH_WEIGHT_MULTIPLIER := 0.4
const NUSHI_ENCOUNTER_CHANCE := 0.04

const BOSS_FIRST_CLEAR_REWARDS: Dictionary = GameCatalogData.BOSS_FIRST_CLEAR_REWARDS
const FISH: Dictionary = GameCatalogData.FISH
const NUSHI_FISH: Dictionary = GameCatalogData.NUSHI_FISH
const COMMON_LOW_LEVEL_FISH_IDS: Array[String] = GameCatalogData.COMMON_LOW_LEVEL_FISH_IDS
const NORMAL_FISHING_SPOT_IDS: Array[String] = GameCatalogData.NORMAL_FISHING_SPOT_IDS
const FISHING_SPOT_ORDER: Array[String] = GameCatalogData.FISHING_SPOT_ORDER
const FISHING_SPOTS: Dictionary = GameCatalogData.FISHING_SPOTS
const FISHING_ENVIRONMENT_ORDER: Array[String] = GameCatalogData.FISHING_ENVIRONMENT_ORDER
const FISHING_ENVIRONMENTS: Dictionary = GameCatalogData.FISHING_ENVIRONMENTS
const TITLES: Array[Dictionary] = GameCatalogData.TITLES
const RECIPES: Dictionary = GameCatalogData.RECIPES
const QUEST_TEMPLATES: Dictionary = GameCatalogData.QUEST_TEMPLATES
const ROD_ORDER: Array[String] = GameCatalogData.ROD_ORDER
const RODS: Dictionary = GameCatalogData.RODS
const RIG_ORDER: Array[String] = GameCatalogData.RIG_ORDER
const RIGS: Dictionary = GameCatalogData.RIGS
const BOAT_ORDER: Array[String] = GameCatalogData.BOAT_ORDER
const BOATS: Dictionary = GameCatalogData.BOATS

const DEFAULT_FISHING_ENVIRONMENT_ID := "sunny_calm"
const SIZE_ROLL_EXPONENT_DEFAULT := 2.1


var _rng := RandomNumberGenerator.new()
var _fish_expansion_cache: Dictionary = {}


func _ready() -> void:
	_rng.randomize()


func get_fish(fish_id: String) -> Dictionary:
	if FISH.has(fish_id):
		return FISH[fish_id].duplicate(true)
	if NUSHI_FISH.has(fish_id):
		return NUSHI_FISH[fish_id].duplicate(true)
	var expansion := _expansion_fish()
	if expansion.has(fish_id):
		return Dictionary(expansion[fish_id]).duplicate(true)
	return {}


func get_boss_first_clear_reward(fish_id: String) -> Dictionary:
	if not BOSS_FIRST_CLEAR_REWARDS.has(fish_id):
		return {}
	return BOSS_FIRST_CLEAR_REWARDS[fish_id].duplicate(true)


func get_fishing_spot(spot_id: String) -> Dictionary:
	var resolved_id := _resolved_spot_id(spot_id)
	return FISHING_SPOTS[resolved_id].duplicate(true)


func get_fishing_environment(environment_id: String) -> Dictionary:
	if not FISHING_ENVIRONMENTS.has(environment_id):
		environment_id = DEFAULT_FISHING_ENVIRONMENT_ID
	return FISHING_ENVIRONMENTS[environment_id].duplicate(true)


func roll_fishing_environment() -> Dictionary:
	var total_weight := 0.0
	for environment_id in get_all_fishing_environment_ids():
		var environment: Dictionary = FISHING_ENVIRONMENTS[environment_id]
		total_weight += maxf(0.0, float(environment.get("weight", 1.0)))
	if total_weight <= 0.0:
		return get_fishing_environment(DEFAULT_FISHING_ENVIRONMENT_ID)
	var target := _rng.randf_range(0.0, total_weight)
	var current := 0.0
	for environment_id in get_all_fishing_environment_ids():
		var environment: Dictionary = FISHING_ENVIRONMENTS[environment_id]
		current += maxf(0.0, float(environment.get("weight", 1.0)))
		if target <= current:
			return environment.duplicate(true)
	return get_fishing_environment(DEFAULT_FISHING_ENVIRONMENT_ID)


func get_recipe(recipe_id: String) -> Dictionary:
	if not RECIPES.has(recipe_id):
		return {}
	var recipe: Dictionary = RECIPES[recipe_id].duplicate(true)
	if bool(recipe.get("allow_all_fish", false)):
		recipe["allowed_fish"] = get_all_fish_ids()
	return recipe


func get_quest_template(template_id: String) -> Dictionary:
	if not QUEST_TEMPLATES.has(template_id):
		return {}
	return QUEST_TEMPLATES[template_id].duplicate(true)


func get_rod(rod_id: String) -> Dictionary:
	if not RODS.has(rod_id):
		return {}
	return RODS[rod_id].duplicate(true)


func get_rig(rig_id: String) -> Dictionary:
	if not RIGS.has(rig_id):
		return {}
	return RIGS[rig_id].duplicate(true)


func get_boat(boat_id: String) -> Dictionary:
	if not BOATS.has(boat_id):
		return {}
	return BOATS[boat_id].duplicate(true)


func get_all_fish_ids() -> Array[String]:
	var ids: Array[String] = []
	for fish_id in FISH.keys():
		ids.append(String(fish_id))
	for fish_id in _expansion_fish().keys():
		ids.append(String(fish_id))
	ids.sort_custom(
		func(a: String, b: String) -> bool:
			var number_a := _fish_no_sort_number(a)
			var number_b := _fish_no_sort_number(b)
			if number_a == number_b:
				return a < b
			return number_a < number_b
	)
	return ids


func get_all_nushi_fish_ids() -> Array[String]:
	var ids: Array[String] = []
	for spot_id in FISHING_SPOT_ORDER:
		var spot: Dictionary = FISHING_SPOTS[spot_id]
		var nushi: Dictionary = spot.get("nushi", {})
		var fish_id := String(nushi.get("fish_id", ""))
		if not fish_id.is_empty() and NUSHI_FISH.has(fish_id):
			ids.append(fish_id)
	return ids


func get_all_sellable_fish_ids() -> Array[String]:
	var ids := get_all_fish_ids()
	for fish_id in get_all_nushi_fish_ids():
		ids.append(fish_id)
	return ids


func get_nushi_for_base_fish(base_fish_id: String) -> Dictionary:
	for nushi_id in get_all_nushi_fish_ids():
		var fish := get_fish(nushi_id)
		if String(fish.get("base_fish_id", "")) == base_fish_id:
			return fish
	return {}


func get_nushi_for_spot(spot_id: String) -> Dictionary:
	var spot := get_fishing_spot(spot_id)
	var nushi: Dictionary = spot.get("nushi", {})
	var fish_id := String(nushi.get("fish_id", ""))
	if fish_id.is_empty():
		return {}
	return get_fish(fish_id)


func get_all_fishing_spot_ids() -> Array[String]:
	var ids: Array[String] = []
	for spot_id in FISHING_SPOT_ORDER:
		ids.append(spot_id)
	return ids


func get_all_fishing_environment_ids() -> Array[String]:
	var ids: Array[String] = []
	for environment_id in FISHING_ENVIRONMENT_ORDER:
		if FISHING_ENVIRONMENTS.has(environment_id):
			ids.append(environment_id)
	return ids


func compute_earned_titles(stats: Dictionary) -> Array[String]:
	var earned: Array[String] = []
	for title in TITLES:
		var title_id := String(title.get("id", ""))
		if title_id.is_empty():
			continue
		if _is_title_earned(title, stats):
			earned.append(title_id)
	return earned


func get_unlocked_fishing_spot_ids(player_level: int) -> Array[String]:
	var ids: Array[String] = []
	for spot_id in FISHING_SPOT_ORDER:
		var spot: Dictionary = FISHING_SPOTS[spot_id]
		if int(spot.get("unlock_level", 1)) <= player_level:
			ids.append(spot_id)
	return ids


func is_fishing_spot_unlocked(spot_id: String, player_level: int) -> bool:
	var spot := get_fishing_spot(spot_id)
	return int(spot.get("unlock_level", 1)) <= player_level


func get_all_rod_ids() -> Array[String]:
	var ids: Array[String] = []
	for rod_id in ROD_ORDER:
		if RODS.has(rod_id):
			ids.append(rod_id)
	return ids


func get_all_rig_ids() -> Array[String]:
	var ids: Array[String] = []
	for rig_id in RIG_ORDER:
		ids.append(rig_id)
	return ids


func rig_bait_types(rig_id: String) -> Array[String]:
	var rig := get_rig(rig_id)
	var bait_types: Array[String] = []
	for bait_variant in Array(rig.get("bait_types", [])):
		bait_types.append(String(bait_variant))
	return bait_types


func rig_supports_bait(rig_id: String, bait_type: String) -> bool:
	if bait_type.strip_edges().is_empty():
		return false
	return rig_bait_types(rig_id).has(bait_type)


func fishing_environment_fish_modifier(environment_id: String, fish_id: String) -> float:
	var fish := get_fish(fish_id)
	if fish.is_empty():
		return 1.0
	return _environment_weight_modifier(fish_id, fish, environment_id)


func get_all_boat_ids() -> Array[String]:
	var ids: Array[String] = []
	for boat_id in BOAT_ORDER:
		ids.append(boat_id)
	return ids


func get_best_boat_rank(owned_boat_ids: Array) -> int:
	var best_rank := NO_BOAT_RANK
	for boat_id_variant in owned_boat_ids:
		var boat := get_boat(String(boat_id_variant))
		if boat.is_empty():
			continue
		best_rank = maxi(best_rank, int(boat.get("rank", NO_BOAT_RANK)))
	return best_rank


func get_required_boat_for_rank(required_rank: int) -> Dictionary:
	if required_rank <= NO_BOAT_RANK:
		return {}
	for boat_id in BOAT_ORDER:
		var boat: Dictionary = BOATS[boat_id]
		if int(boat.get("rank", NO_BOAT_RANK)) >= required_rank:
			return boat.duplicate(true)
	return {}


func fishing_spot_access_status(spot_id: String, player_level: int, owned_boat_ids: Array) -> Dictionary:
	var resolved_id := _resolved_spot_id(spot_id)
	var spot: Dictionary = FISHING_SPOTS[resolved_id]
	var unlock_level := int(spot.get("unlock_level", 1))
	var required_rank := int(spot.get("required_boat_rank", NO_BOAT_RANK))
	var owned_rank := get_best_boat_rank(owned_boat_ids)
	if player_level < unlock_level:
		return {
			"ok": false,
			"spot_id": resolved_id,
			"reason": "level",
			"message": "未発見　Lv.%dで発見" % unlock_level,
			"detail": "プレイヤーレベルが足りません。",
			"button_text": "Lv.%dで解放" % unlock_level,
			"required_level": unlock_level,
			"required_boat_rank": required_rank,
			"owned_boat_rank": owned_rank,
		}

	if owned_rank < required_rank:
		var required_boat := get_required_boat_for_rank(required_rank)
		var boat_name := String(required_boat.get("name", "船"))
		return {
			"ok": false,
			"spot_id": resolved_id,
			"reason": "boat",
			"message": "出航不可　%sが必要" % boat_name,
			"detail": "%sを購入すると、この釣り場へ出航できます。" % boat_name,
			"button_text": "%sが必要" % String(required_boat.get("short_name", boat_name)),
			"required_level": unlock_level,
			"required_boat_rank": required_rank,
			"owned_boat_rank": owned_rank,
			"required_boat_id": String(required_boat.get("id", "")),
			"required_boat_name": boat_name,
		}

	return {
		"ok": true,
		"spot_id": resolved_id,
		"reason": "",
		"message": "出航可能",
		"detail": "この釣り場へ出航できます。",
		"button_text": "ここで釣る",
		"required_level": unlock_level,
		"required_boat_rank": required_rank,
		"owned_boat_rank": owned_rank,
	}


func is_fishing_spot_accessible(spot_id: String, player_level: int, owned_boat_ids: Array) -> bool:
	return bool(fishing_spot_access_status(spot_id, player_level, owned_boat_ids).get("ok", false))


func get_accessible_fishing_spot_ids(player_level: int, owned_boat_ids: Array) -> Array[String]:
	var ids: Array[String] = []
	for spot_id in FISHING_SPOT_ORDER:
		if is_fishing_spot_accessible(spot_id, player_level, owned_boat_ids):
			ids.append(spot_id)
	return ids


func quest_template_weights(player_level: int) -> Dictionary:
	if player_level >= 8:
		return {
			"bulk_common": 30.0,
			"bulk_uncommon": 25.0,
			"cuisine": 15.0,
			"size_record": 15.0,
			"rare_order": 15.0,
		}
	return {
		"bulk_common": 50.0,
		"bulk_uncommon": 25.0,
		"cuisine": 15.0,
		"size_record": 10.0,
	}


func generate_quest(context: Dictionary) -> Dictionary:
	var forced_template_id := String(context.get("template_id", ""))
	if not forced_template_id.is_empty():
		return _build_quest_from_template(forced_template_id, context)
	var weights := quest_template_weights(int(context.get("player_level", 1)))
	var available_weights: Dictionary = {}
	for template_id_variant in weights.keys():
		var template_id := String(template_id_variant)
		if _quest_has_candidate(template_id, context):
			available_weights[template_id] = float(weights[template_id])
	return _build_quest_from_template(_roll_weighted_key(available_weights), context)


func generate_quest_board(context: Dictionary, count: int = 3) -> Array[Dictionary]:
	var quests: Array[Dictionary] = []
	var working_context := context.duplicate(true)
	var attempts := 0
	while quests.size() < count and attempts < count * 8:
		attempts += 1
		working_context["existing_quests"] = quests.duplicate(true)
		var quest := generate_quest(working_context)
		if quest.is_empty():
			break
		quests.append(quest)
	return quests


func quest_progress(quest: Dictionary, stats: Dictionary) -> Dictionary:
	var kind := String(quest.get("kind", "delivery"))
	var fish_id := String(quest.get("fish_id", ""))
	if kind == "record":
		var best_sizes := _stats_dictionary(stats, "best_sizes")
		var current_size := float(best_sizes.get(fish_id, 0.0))
		var target_size := float(quest.get("target_size_cm", 0.0))
		return {
			"kind": "record",
			"fish_id": fish_id,
			"current": current_size,
			"target": target_size,
			"completed": current_size >= target_size and target_size > 0.0,
			"action_label": "報告",
			"progress_text": "%.1f / %.1f cm" % [current_size, target_size],
		}
	var inventory := _stats_dictionary(stats, "inventory")
	var current_count := int(inventory.get(fish_id, 0))
	var target_count := int(quest.get("count", 0))
	return {
		"kind": "delivery",
		"fish_id": fish_id,
		"current": current_count,
		"target": target_count,
		"completed": current_count >= target_count and target_count > 0,
		"action_label": "納品",
		"progress_text": "%d / %d 匹" % [current_count, target_count],
	}


func _build_quest_from_template(template_id: String, context: Dictionary) -> Dictionary:
	if template_id.is_empty() or not QUEST_TEMPLATES.has(template_id):
		return {}
	var template: Dictionary = QUEST_TEMPLATES[template_id]
	var player_level := int(context.get("player_level", 1))
	if player_level < int(template.get("min_level", 1)):
		return {}
	match template_id:
		"bulk_common", "bulk_uncommon", "rare_order":
			return _build_bulk_quest(template, context)
		"cuisine":
			return _build_cuisine_quest(template, context)
		"size_record":
			return _build_size_record_quest(template, context)
		_:
			return {}


func _build_bulk_quest(template: Dictionary, context: Dictionary) -> Dictionary:
	var rarity := String(template.get("rarity", ""))
	var candidates := _quest_candidate_fish_ids(context, rarity)
	if candidates.is_empty():
		return {}
	var fish_id := _pick_string(candidates)
	var fish := get_fish(fish_id)
	var count := _rng.randi_range(int(template.get("min_count", 1)), int(template.get("max_count", 1)))
	var multiplier := float(template.get("reward_multiplier", 1.0))
	var reward := int(round(float(fish.get("sell_price", 0)) * float(count) * multiplier))
	var text := ""
	match String(template.get("id", "")):
		"bulk_uncommon":
			text = "%sを%d匹。上物を頼む" % [String(fish.get("name", fish_id)), count]
		"rare_order":
			text = "%sを探している。金は弾む" % String(fish.get("name", fish_id))
		_:
			text = "%sを%d匹届けてほしい" % [String(fish.get("name", fish_id)), count]
	return {
		"template_id": String(template.get("id", "")),
		"kind": "delivery",
		"fish_id": fish_id,
		"count": count,
		"reward_money": reward,
		"text": text,
	}


func _build_cuisine_quest(template: Dictionary, context: Dictionary) -> Dictionary:
	var options := _quest_cuisine_options(context)
	if options.is_empty():
		return {}
	var option: Dictionary = options[_rng.randi_range(0, options.size() - 1)]
	var fish_id := String(option.get("fish_id", ""))
	var recipe_id := String(option.get("recipe_id", ""))
	var fish := get_fish(fish_id)
	var recipe := get_recipe(recipe_id)
	var reward := int(round(float(fish.get("sell_price", 0)) * float(template.get("reward_multiplier", 1.0))))
	return {
		"template_id": "cuisine",
		"kind": "delivery",
		"fish_id": fish_id,
		"recipe_id": recipe_id,
		"count": 1,
		"reward_money": reward,
		"text": "%sにする%sを1匹" % [
			String(recipe.get("name", "料理")),
			String(fish.get("name", fish_id)),
		],
	}


func _build_size_record_quest(template: Dictionary, context: Dictionary) -> Dictionary:
	var candidates := _quest_candidate_fish_ids(context)
	if candidates.is_empty():
		return {}
	var fish_id := _pick_string(candidates)
	var fish := get_fish(fish_id)
	var size_min := float(fish.get("size_min", 0.0))
	var size_max := float(fish.get("size_max", size_min))
	var target := snappedf(
		size_min + (size_max - size_min) * float(template.get("target_ratio", 0.62)),
		float(template.get("target_snap_cm", 5.0))
	)
	var best_sizes := _stats_dictionary(context, "best_sizes")
	return {
		"template_id": "size_record",
		"kind": "record",
		"fish_id": fish_id,
		"target_size_cm": target,
		"posted_best_cm": float(best_sizes.get(fish_id, 0.0)),
		"reward_money": int(round(float(fish.get("sell_price", 0)) * float(template.get("reward_multiplier", 1.0)))),
		"text": "%.0fcm以上の%sを釣り上げてくれ" % [target, String(fish.get("name", fish_id))],
	}


func _quest_has_candidate(template_id: String, context: Dictionary) -> bool:
	match template_id:
		"bulk_common", "bulk_uncommon", "rare_order":
			var template: Dictionary = QUEST_TEMPLATES[template_id]
			return not _quest_candidate_fish_ids(context, String(template.get("rarity", ""))).is_empty()
		"cuisine":
			return not _quest_cuisine_options(context).is_empty()
		"size_record":
			return not _quest_candidate_fish_ids(context).is_empty()
		_:
			return false


func _quest_candidate_fish_ids(context: Dictionary, rarity: String = "") -> Array[String]:
	var excluded := _quest_excluded_fish_ids(context)
	var ids: Array[String] = []
	var player_level := int(context.get("player_level", 1))
	var owned_boats := Array(context.get("owned_boats", []))
	var spot_ids := Array(context.get("spot_ids", []))
	if spot_ids.is_empty():
		spot_ids = get_accessible_fishing_spot_ids(player_level, owned_boats)
	for spot_id_variant in spot_ids:
		var spot := get_fishing_spot(String(spot_id_variant))
		for fish_id_variant in Array(spot.get("allowed_fish", [])):
			var fish_id := String(fish_id_variant)
			if ids.has(fish_id) or excluded.has(fish_id):
				continue
			var fish := get_fish(fish_id)
			if fish.is_empty() or _quest_excludes_fish(fish_id, fish):
				continue
			if int(fish.get("min_level", 1)) > player_level:
				continue
			if not rarity.is_empty() and String(fish.get("rarity", "")) != rarity:
				continue
			ids.append(fish_id)
	return ids


func _quest_cuisine_options(context: Dictionary) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var candidates := _quest_candidate_fish_ids(context)
	var player_level := int(context.get("player_level", 1))
	var recipe_ids: Array[String] = []
	for recipe_id_variant in RECIPES.keys():
		recipe_ids.append(String(recipe_id_variant))
	recipe_ids.sort()
	for recipe_id in recipe_ids:
		var recipe := get_recipe(recipe_id)
		if int(recipe.get("unlock_level", 1)) > player_level:
			continue
		var allowed_fish := Array(recipe.get("allowed_fish", []))
		for fish_id in candidates:
			if allowed_fish.has(fish_id):
				options.append({"recipe_id": recipe_id, "fish_id": fish_id})
	return options


func _quest_excluded_fish_ids(context: Dictionary) -> Array[String]:
	var excluded: Array[String] = []
	for fish_id_variant in Array(context.get("exclude_fish_ids", [])):
		var fish_id := String(fish_id_variant)
		if not excluded.has(fish_id):
			excluded.append(fish_id)
	for quest_variant in Array(context.get("existing_quests", [])):
		if typeof(quest_variant) != TYPE_DICTIONARY:
			continue
		var fish_id := String(Dictionary(quest_variant).get("fish_id", ""))
		if not fish_id.is_empty() and not excluded.has(fish_id):
			excluded.append(fish_id)
	return excluded


func _quest_excludes_fish(fish_id: String, fish: Dictionary) -> bool:
	return (
		bool(fish.get("shark", false))
		or bool(fish.get("nushi", false))
		or bool(fish.get("boss", false))
		or NUSHI_FISH.has(fish_id)
	)


func _roll_weighted_key(weights: Dictionary) -> String:
	var total_weight := 0.0
	for key in weights.keys():
		total_weight += maxf(0.0, float(weights[key]))
	if total_weight <= 0.0:
		return ""
	var pick := _rng.randf_range(0.0, total_weight)
	var running := 0.0
	for key in weights.keys():
		running += maxf(0.0, float(weights[key]))
		if pick <= running:
			return String(key)
	return String(weights.keys().back())


func _pick_string(values: Array[String]) -> String:
	if values.is_empty():
		return ""
	return values[_rng.randi_range(0, values.size() - 1)]


func _expansion_fish() -> Dictionary:
	if _fish_expansion_cache.is_empty():
		_fish_expansion_cache = FishExpansionData.all_fish()
	return _fish_expansion_cache


func _fish_no_sort_number(fish_id: String) -> int:
	var fish_no := String(get_fish(fish_id).get("fish_no", ""))
	var digits := fish_no.replace("No.", "").strip_edges()
	return int(digits)


func get_recipes_for_fish(fish_id: String, player_level: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for recipe_id in RECIPES.keys():
		var recipe := get_recipe(String(recipe_id))
		if int(recipe["unlock_level"]) > player_level:
			continue
		if fish_id not in recipe["allowed_fish"]:
			continue
		results.append(recipe.duplicate(true))
	results.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["unlock_level"]) < int(b["unlock_level"])
	)
	return results


func nushi_candidate(
	spot_id: String,
	environment_id: String,
	rig_id: String,
	time_slot_id: String,
	player_level: int
) -> Dictionary:
	var resolved_id := _resolved_spot_id(spot_id)
	var spot: Dictionary = FISHING_SPOTS[resolved_id]
	var nushi: Dictionary = spot.get("nushi", {})
	if nushi.is_empty():
		return {}
	var fish_id := String(nushi.get("fish_id", ""))
	var required_environment := String(nushi.get("environment_id", ""))
	var required_rig := String(nushi.get("rig_id", ""))
	var required_time_slot := String(nushi.get("time_slot_id", ""))
	if fish_id.is_empty() or not NUSHI_FISH.has(fish_id):
		return {}
	if not required_environment.is_empty() and environment_id != required_environment:
		return {}
	if not required_rig.is_empty() and rig_id != required_rig:
		return {}
	if not required_time_slot.is_empty() and time_slot_id != required_time_slot:
		return {}
	var fish := get_fish(fish_id)
	if int(fish.get("min_level", 1)) > player_level:
		return {}
	return fish


func encounter_weights(
	player_level: int,
	spot_id: String = DEFAULT_FISHING_SPOT_ID,
	rig_id: String = "",
	environment_id: String = ""
) -> Dictionary:
	var requested_spot_id := _resolved_spot_id(spot_id)
	var requested_spot: Dictionary = FISHING_SPOTS[requested_spot_id]
	var resolved_id := _normal_spot_id_for_roll(spot_id, player_level)
	var spot: Dictionary = FISHING_SPOTS[resolved_id]
	var weights: Dictionary = {}
	var allowed_fish: Array = spot.get("allowed_fish", [])
	var modifiers: Dictionary = spot.get("fish_weight_modifiers", {})
	var common_modifier := float(spot.get("common_modifier", 1.0))
	var apply_rig_modifier := (
		not rig_id.strip_edges().is_empty()
		and not bool(requested_spot.get("boss_spot", false))
	)
	var apply_environment_modifier := (
		not environment_id.strip_edges().is_empty()
		and not bool(requested_spot.get("boss_spot", false))
	)
	for fish_id in get_all_fish_ids():
		var fish := get_fish(fish_id)
		if bool(fish.get("boss", false)):
			continue
		if int(fish.get("min_level", 1)) > player_level:
			continue
		if not allowed_fish.has(fish_id):
			continue
		var modifier := common_modifier
		if modifiers.has(fish_id):
			modifier = float(modifiers[fish_id])
		if apply_rig_modifier:
			modifier *= _rig_weight_modifier(fish, rig_id)
		if apply_environment_modifier:
			modifier *= _environment_weight_modifier(fish_id, fish, environment_id)
		var weight := float(fish.get("weight", 0.0)) * maxf(0.0, modifier)
		if weight <= 0.0:
			continue
		weights[fish_id] = weight
	return weights


func roll_hooked_fish(
	player_level: int,
	spot_id: String = DEFAULT_FISHING_SPOT_ID,
	rig_id: String = "",
	environment_id: String = "",
	time_slot_id: String = ""
) -> Dictionary:
	var nushi := nushi_candidate(spot_id, environment_id, rig_id, time_slot_id, player_level)
	if not nushi.is_empty() and _rng.randf() < NUSHI_ENCOUNTER_CHANCE:
		return nushi
	return roll_normal_fish(player_level, spot_id, rig_id, environment_id)


func roll_normal_fish(
	player_level: int,
	spot_id: String = DEFAULT_FISHING_SPOT_ID,
	rig_id: String = "",
	environment_id: String = ""
) -> Dictionary:
	var weights := encounter_weights(player_level, spot_id, rig_id, environment_id)
	var candidate_ids: Array[String] = []
	var total_weight := 0.0
	for fish_id_variant in weights.keys():
		var fish_id := String(fish_id_variant)
		candidate_ids.append(fish_id)
		total_weight += float(weights[fish_id])

	if candidate_ids.is_empty() or total_weight <= 0.0:
		return get_fish("aji")

	var pick := _rng.randf_range(0.0, total_weight)
	var running := 0.0
	for fish_id in candidate_ids:
		running += float(weights[fish_id])
		if pick <= running:
			return get_fish(fish_id)
	return get_fish(candidate_ids.back())


func roll_fish_size(fish: Dictionary) -> float:
	var exponent := float(fish.get("size_bias", SIZE_ROLL_EXPONENT_DEFAULT))
	var t := pow(_rng.randf(), exponent)
	return snappedf(lerpf(float(fish["size_min"]), float(fish["size_max"]), t), 0.1)


func recipe_exp(fish_id: String, recipe_id: String) -> int:
	var fish := get_fish(fish_id)
	var recipe := get_recipe(recipe_id)
	if fish.is_empty() or recipe.is_empty():
		return 0
	return int(round(float(fish["food_exp"]) * float(recipe["exp_multiplier"])))


func _is_title_earned(title: Dictionary, stats: Dictionary) -> bool:
	var title_type := String(title.get("type", ""))
	match title_type:
		"total_catches":
			return _title_total_catches(stats) >= int(title.get("value", 0))
		"species_count":
			return _title_species_count(stats) >= int(title.get("value", 0))
		"fish_count":
			return _title_fish_count(stats, String(title.get("fish_id", ""))) >= int(title.get("value", 0))
		"best_size":
			return _title_best_size(stats, String(title.get("fish_id", ""))) >= float(title.get("value", 0.0))
		"spots_complete":
			return _title_spots_complete(stats, Array(title.get("spot_ids", [])))
		"level":
			return int(stats.get("level", 1)) >= int(title.get("value", 0))
		"dish_total":
			return _title_dish_total(stats) >= int(title.get("value", 0))
		"quest_completed":
			return int(stats.get("quest_completed_count", 0)) >= int(title.get("value", 0))
		"fish_caught_any":
			return _title_fish_caught_any(stats, Array(title.get("fish_ids", [])))
		"fish_caught_all":
			return _title_fish_caught_all(stats, Array(title.get("fish_ids", [])))
		"shark_bond":
			return _title_shark_bond(stats, String(title.get("shark_id", ""))) >= int(title.get("value", 100))
		"shark_bond_all":
			return _title_shark_bond_all(stats, Array(title.get("shark_ids", [])), int(title.get("value", 100)))
		_:
			return false


func _title_total_catches(stats: Dictionary) -> int:
	var caught_counts := _stats_dictionary(stats, "caught_counts")
	var total := 0
	for fish_id in caught_counts.keys():
		total += int(caught_counts[fish_id])
	return total


func _title_species_count(stats: Dictionary) -> int:
	var caught_counts := _stats_dictionary(stats, "caught_counts")
	var total := 0
	for fish_id in caught_counts.keys():
		if int(caught_counts[fish_id]) > 0:
			total += 1
	return total


func _title_fish_count(stats: Dictionary, fish_id: String) -> int:
	if fish_id.is_empty():
		return 0
	var caught_counts := _stats_dictionary(stats, "caught_counts")
	return int(caught_counts.get(fish_id, 0))


func _title_best_size(stats: Dictionary, fish_id: String) -> float:
	if fish_id.is_empty():
		return 0.0
	var best_sizes := _stats_dictionary(stats, "best_sizes")
	return float(best_sizes.get(fish_id, 0.0))


func _title_spots_complete(stats: Dictionary, spot_ids: Array) -> bool:
	if spot_ids.is_empty():
		return false
	var spot_caught_counts := _stats_dictionary(stats, "spot_caught_counts")
	for spot_id_variant in spot_ids:
		var spot_id := String(spot_id_variant)
		var spot_counts := _dictionary_value(spot_caught_counts.get(spot_id, {}))
		var has_catch := false
		for fish_id in spot_counts.keys():
			if int(spot_counts[fish_id]) > 0:
				has_catch = true
				break
		if not has_catch:
			return false
	return true


func _title_dish_total(stats: Dictionary) -> int:
	var eaten_recipes := _stats_dictionary(stats, "eaten_recipes")
	var total := 0
	for dish_key in eaten_recipes.keys():
		total += int(eaten_recipes[dish_key])
	return total


func _title_fish_caught_any(stats: Dictionary, fish_ids: Array) -> bool:
	if fish_ids.is_empty():
		return false
	var caught_counts := _stats_dictionary(stats, "caught_counts")
	for fish_id_variant in fish_ids:
		if int(caught_counts.get(String(fish_id_variant), 0)) > 0:
			return true
	return false


func _title_fish_caught_all(stats: Dictionary, fish_ids: Array) -> bool:
	if fish_ids.is_empty():
		return false
	var caught_counts := _stats_dictionary(stats, "caught_counts")
	for fish_id_variant in fish_ids:
		if int(caught_counts.get(String(fish_id_variant), 0)) <= 0:
			return false
	return true


func _title_shark_bond(stats: Dictionary, shark_id: String) -> int:
	if shark_id.is_empty():
		return 0
	var shark_bonds := _stats_dictionary(stats, "shark_bonds")
	return int(shark_bonds.get(shark_id, 0))


func _title_shark_bond_all(stats: Dictionary, shark_ids: Array, required_bond: int) -> bool:
	if shark_ids.is_empty():
		return false
	var shark_bonds := _stats_dictionary(stats, "shark_bonds")
	for shark_id_variant in shark_ids:
		if int(shark_bonds.get(String(shark_id_variant), 0)) < required_bond:
			return false
	return true


func _stats_dictionary(stats: Dictionary, key: String) -> Dictionary:
	return _dictionary_value(stats.get(key, {}))


func _dictionary_value(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return Dictionary(value)


func _resolved_spot_id(spot_id: String) -> String:
	if FISHING_SPOTS.has(spot_id):
		return spot_id
	return DEFAULT_FISHING_SPOT_ID


func _normal_spot_id_for_roll(spot_id: String, player_level: int) -> String:
	var resolved_id := _resolved_spot_id(spot_id)
	var spot: Dictionary = FISHING_SPOTS[resolved_id]
	if bool(spot.get("boss_spot", false)):
		return DEFAULT_FISHING_SPOT_ID
	if int(spot.get("unlock_level", 1)) > player_level:
		return DEFAULT_FISHING_SPOT_ID
	return resolved_id


func _rig_weight_modifier(fish: Dictionary, rig_id: String) -> float:
	var rig := get_rig(rig_id)
	if rig.is_empty():
		return 1.0
	var preferred_bait := String(fish.get("preferred_bait", ""))
	if rig_supports_bait(rig_id, preferred_bait):
		return RIG_MATCH_WEIGHT_MULTIPLIER
	return RIG_MISMATCH_WEIGHT_MULTIPLIER


func _environment_weight_modifier(fish_id: String, _fish: Dictionary, environment_id: String) -> float:
	var environment := get_fishing_environment(environment_id)
	if environment.is_empty():
		return 1.0
	var modifiers: Dictionary = environment.get("fish_weight_modifiers", {})
	if not modifiers.has(fish_id):
		return 1.0
	return maxf(0.0, float(modifiers[fish_id]))
