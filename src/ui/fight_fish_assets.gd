extends RefCounted

const FISH_ASSET_DIR := "res://assets/showcase/fish"
const LEGACY_SHEET_PATH := "res://assets/showcase/fish/kurodai_showcase_sheet.png"
const LEGACY_CARD_PORTRAIT_PATH := "res://assets/showcase/fish/kurodai_card_portrait.png"


static func asset_id(fish_data: Dictionary) -> String:
	var explicit_id := String(fish_data.get("asset_id", ""))
	if not explicit_id.is_empty():
		return explicit_id
	var fish_id := String(fish_data.get("id", ""))
	if fish_id == "boss_kurodai":
		return "kurodai"
	return fish_id


static func sheet_path(fish_data: Dictionary) -> String:
	var id := asset_id(fish_data)
	if id.is_empty():
		return LEGACY_SHEET_PATH
	return "%s/%s_showcase_sheet.png" % [FISH_ASSET_DIR, id]


static func card_portrait_path(fish_data: Dictionary) -> String:
	var id := asset_id(fish_data)
	if id.is_empty():
		return LEGACY_CARD_PORTRAIT_PATH
	return "%s/%s_card_portrait.png" % [FISH_ASSET_DIR, id]
