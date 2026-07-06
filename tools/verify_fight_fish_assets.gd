extends SceneTree

const FightFishAssetsScript = preload("res://src/ui/fight_fish_assets.gd")
const GameDataScript = preload("res://src/autoload/game_data.gd")


func _initialize() -> void:
	var game_data := GameDataScript.new()
	var fish_ids := game_data.get_all_fish_ids()
	var nushi_ids := game_data.get_all_nushi_fish_ids()
	var missing: Array[String] = []
	if fish_ids.size() != 70:
		missing.append("expected 70 fight fish ids, got %d" % fish_ids.size())
	if nushi_ids.size() != 7:
		missing.append("expected 7 E2 nushi fish ids, got %d" % nushi_ids.size())
	for fish_id in nushi_ids:
		fish_ids.append(fish_id)
	var required_keys: Array[String] = [
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
		var sheet_path := FightFishAssetsScript.sheet_path(fish)
		var card_path := FightFishAssetsScript.card_portrait_path(fish)
		var sheet := _load_texture(sheet_path)
		var card := _load_texture(card_path)
		if sheet == null:
			missing.append("%s sheet %s" % [fish_id, sheet_path])
		if card == null:
			missing.append("%s card %s" % [fish_id, card_path])
		if not bool(fish.get("nushi", false)) and not fish.has("fish_no"):
			missing.append("%s data missing fish_no" % fish_id)
		if bool(fish.get("nushi", false)) and String(fish.get("base_fish_id", "")).is_empty():
			missing.append("%s nushi data missing base_fish_id" % fish_id)
		for key in required_keys:
			if not fish.has(key):
				missing.append("%s data missing %s" % [fish_id, key])
		if fish.has("action_profile"):
			var profile: Dictionary = fish.get("action_profile", {})
			var total := float(profile.get("dash", 0.0)) + float(profile.get("dive", 0.0)) + float(profile.get("turn", 0.0)) + float(profile.get("rest", 0.0))
			if total <= 0.0:
				missing.append("%s action_profile has no weight" % fish_id)
		if fish.has("visual_scale") and float(fish.get("visual_scale", 0.0)) <= 0.0:
			missing.append("%s visual_scale must be positive" % fish_id)
		if sheet != null and card != null:
			print("%s -> sheet=%s %s card=%s %s" % [fish_id, sheet_path, sheet.get_size(), card_path, card.get_size()])
	if not missing.is_empty():
		for item in missing:
			push_error("Missing fight fish asset: %s" % item)
		game_data.free()
		quit(1)
		return
	game_data.free()
	quit(0)


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		return null
	return load(path) as Texture2D
