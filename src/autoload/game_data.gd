extends Node

const FishExpansionData = preload("res://src/autoload/fish_expansion_data.gd")
const GameCatalogData = preload("res://src/autoload/game_catalog_data.gd")

const MAX_LEVEL: int = 10
const BOSS_UNLOCK_LEVEL: int = 5
const DEFAULT_FISHING_SPOT_ID := "harbor_pier"
const BOSS_FISHING_SPOT_ID := "harbor_boulder"
const NO_BOAT_RANK := 0
const DEFAULT_RIG_ID := "sabiki"
const RIG_MATCH_WEIGHT_MULTIPLIER := 2.5
const RIG_MISMATCH_WEIGHT_MULTIPLIER := 0.4

const BOSS_FIRST_CLEAR_REWARDS: Dictionary = GameCatalogData.BOSS_FIRST_CLEAR_REWARDS
const FISH: Dictionary = GameCatalogData.FISH
const COMMON_LOW_LEVEL_FISH_IDS: Array[String] = GameCatalogData.COMMON_LOW_LEVEL_FISH_IDS
const NORMAL_FISHING_SPOT_IDS: Array[String] = GameCatalogData.NORMAL_FISHING_SPOT_IDS
const FISHING_SPOT_ORDER: Array[String] = GameCatalogData.FISHING_SPOT_ORDER
const FISHING_SPOTS: Dictionary = GameCatalogData.FISHING_SPOTS
const FISHING_ENVIRONMENT_ORDER: Array[String] = GameCatalogData.FISHING_ENVIRONMENT_ORDER
const FISHING_ENVIRONMENTS: Dictionary = GameCatalogData.FISHING_ENVIRONMENTS
const RECIPES: Dictionary = GameCatalogData.RECIPES
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
	if not FISH.has(fish_id):
		var expansion := _expansion_fish()
		if not expansion.has(fish_id):
			return {}
		return Dictionary(expansion[fish_id]).duplicate(true)
	return FISH[fish_id].duplicate(true)


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
