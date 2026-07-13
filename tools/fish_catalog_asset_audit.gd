extends Node

const FightFishAssetsScript = preload("res://src/ui/fight_fish_assets.gd")
const ACTION_KEYS: Array[String] = ["dash", "dive", "turn", "rest"]

var _failures: Array[String] = []


func _ready() -> void:
	_verify_path_contract_self_test()

	var normal_ids := GameData.get_all_fish_ids()
	var nushi_ids := GameData.get_all_nushi_fish_ids()
	var seen_ids: Dictionary = {}
	for fish_id in normal_ids:
		_audit_fish_id(fish_id, false, seen_ids)
	for fish_id in nushi_ids:
		_audit_fish_id(fish_id, true, seen_ids)

	if not _failures.is_empty():
		printerr("fish_catalog_asset_audit: failed (%d problems)" % _failures.size())
		for failure in _failures:
			printerr("- %s" % failure)
		get_tree().quit(1)
		return

	print(
		"fish_catalog_asset_audit: ok %d fish (%d normal, %d nushi)"
		% [seen_ids.size(), normal_ids.size(), nushi_ids.size()]
	)
	get_tree().quit(0)


func _audit_fish_id(fish_id: String, is_nushi: bool, seen_ids: Dictionary) -> void:
	if fish_id.strip_edges().is_empty():
		_failures.append("catalog contains an empty fish id")
		return
	if seen_ids.has(fish_id):
		_failures.append("duplicate catalog fish id: %s" % fish_id)
		return
	seen_ids[fish_id] = true

	var fish := GameData.get_fish(fish_id)
	if fish.is_empty():
		_failures.append("%s: GameData.get_fish could not resolve catalog id" % fish_id)
		return
	if String(fish.get("id", "")) != fish_id:
		_failures.append(
			"%s: resolved data id mismatch (%s)" % [fish_id, String(fish.get("id", ""))]
		)

	_validate_catalog_metadata(fish_id, fish, is_nushi)

	var asset_id := FightFishAssetsScript.asset_id(fish)
	if asset_id.strip_edges().is_empty():
		_failures.append("%s: FightFishAssets.asset_id resolved empty" % fish_id)
	_audit_texture(fish_id, "sheet", FightFishAssetsScript.sheet_path(fish))
	_audit_texture(fish_id, "card", FightFishAssetsScript.card_portrait_path(fish))


func _validate_catalog_metadata(fish_id: String, fish: Dictionary, is_nushi: bool) -> void:
	if is_nushi:
		var base_fish_id := String(fish.get("base_fish_id", ""))
		if base_fish_id.strip_edges().is_empty():
			_failures.append("%s: nushi data missing base_fish_id" % fish_id)
		elif GameData.get_fish(base_fish_id).is_empty():
			_failures.append("%s: base_fish_id does not resolve (%s)" % [fish_id, base_fish_id])
	elif not fish.has("fish_no") or typeof(fish["fish_no"]) != TYPE_STRING:
		_failures.append("%s: normal fish data missing String fish_no" % fish_id)

	if not fish.has("preferred_bait") or typeof(fish["preferred_bait"]) != TYPE_STRING:
		_failures.append("%s: missing String preferred_bait" % fish_id)
	elif String(fish["preferred_bait"]).strip_edges().is_empty():
		_failures.append("%s: preferred_bait must not be empty" % fish_id)

	if not _is_finite_number(fish.get("visual_scale", null)):
		_failures.append("%s: visual_scale must be a finite number" % fish_id)
	elif float(fish["visual_scale"]) <= 0.0:
		_failures.append("%s: visual_scale must be positive" % fish_id)

	for key in ["line_anchor_x", "line_anchor_y"]:
		if not _is_finite_number(fish.get(key, null)):
			_failures.append("%s: %s must be a finite number" % [fish_id, key])

	var motion_value = fish.get("motion", null)
	if typeof(motion_value) != TYPE_DICTIONARY or Dictionary(motion_value).is_empty():
		_failures.append("%s: motion must be a non-empty Dictionary" % fish_id)

	var profile_value = fish.get("action_profile", null)
	if typeof(profile_value) != TYPE_DICTIONARY:
		_failures.append("%s: action_profile must be a Dictionary" % fish_id)
	else:
		var total_weight := 0.0
		var profile := Dictionary(profile_value)
		for key in ACTION_KEYS:
			var weight = profile.get(key, null)
			if not _is_finite_number(weight):
				_failures.append("%s: action_profile.%s must be a finite number" % [fish_id, key])
				continue
			if float(weight) < 0.0:
				_failures.append("%s: action_profile.%s must not be negative" % [fish_id, key])
			total_weight += float(weight)
		if not is_finite(total_weight) or total_weight <= 0.0:
			_failures.append("%s: action_profile total weight must be positive" % fish_id)

	var messages_value = fish.get("action_messages", null)
	if typeof(messages_value) != TYPE_DICTIONARY:
		_failures.append("%s: action_messages must be a Dictionary" % fish_id)
	else:
		var messages := Dictionary(messages_value)
		for key in ACTION_KEYS:
			if typeof(messages.get(key, null)) != TYPE_STRING or String(
				messages.get(key, "")
			).strip_edges().is_empty():
				_failures.append("%s: action_messages.%s must be a non-empty String" % [fish_id, key])


func _audit_texture(fish_id: String, kind: String, path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	var resource_exists := ResourceLoader.exists(path)
	var file_exists := FileAccess.file_exists(absolute_path)
	var availability_error := _path_availability_error(path, resource_exists, file_exists)
	if not availability_error.is_empty():
		_failures.append("%s: %s %s" % [fish_id, kind, availability_error])
		return

	var texture := _load_texture(path, resource_exists, file_exists, absolute_path)
	if texture == null:
		_failures.append("%s: %s is not loadable as Texture2D (%s)" % [fish_id, kind, path])
		return
	var size := texture.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		_failures.append("%s: %s has invalid dimensions %s (%s)" % [fish_id, kind, size, path])


func _load_texture(
	path: String,
	resource_exists: bool,
	file_exists: bool,
	absolute_path: String
) -> Texture2D:
	if resource_exists:
		var resource_texture := load(path) as Texture2D
		if resource_texture != null:
			return resource_texture
	if file_exists:
		var image := Image.new()
		if image.load(absolute_path) == OK:
			return ImageTexture.create_from_image(image)
	return null


func _path_availability_error(path: String, resource_exists: bool, file_exists: bool) -> String:
	if path.strip_edges().is_empty():
		return "path is empty"
	if not resource_exists and not file_exists:
		return "is missing from ResourceLoader and globalized filesystem (%s)" % path
	return ""


func _verify_path_contract_self_test() -> void:
	var cases: Array[Dictionary] = [
		{"label": "empty", "path": "", "resource": true, "file": true, "valid": false},
		{"label": "missing", "path": "res://missing.png", "resource": false, "file": false, "valid": false},
		{"label": "resource", "path": "res://resource.png", "resource": true, "file": false, "valid": true},
		{"label": "globalized", "path": "res://raw.png", "resource": false, "file": true, "valid": true},
	]
	for test_case in cases:
		var error := _path_availability_error(
			String(test_case["path"]),
			bool(test_case["resource"]),
			bool(test_case["file"])
		)
		var actual_valid := error.is_empty()
		if actual_valid != bool(test_case["valid"]):
			_failures.append(
				"path contract self-test %s failed (error=%s)"
				% [String(test_case["label"]), error]
			)


func _is_finite_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))
