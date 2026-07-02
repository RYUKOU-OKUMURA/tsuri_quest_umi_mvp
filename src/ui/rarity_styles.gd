class_name RarityStyles
extends RefCounted


static func text_color(rarity: String) -> Color:
	match rarity:
		"コモン":
			return Palette.RARITY_COMMON_TEXT
		"アンコモン":
			return Palette.RARITY_UNCOMMON_TEXT
		"レア":
			return Palette.RARITY_RARE_TEXT
		"ぬし":
			return Palette.RARITY_BOSS_TEXT
		_:
			return Palette.TEXT_BONE


static func badge_color(rarity: String) -> Color:
	match rarity:
		"コモン":
			return Palette.RARITY_COMMON_BADGE
		"アンコモン":
			return Palette.RARITY_UNCOMMON_BADGE
		"レア":
			return Palette.RARITY_RARE_BADGE
		"ぬし":
			return Palette.RARITY_BOSS_BADGE
		_:
			return Palette.RARITY_UNKNOWN_BADGE


static func border_color(rarity: String) -> Color:
	match rarity:
		"コモン":
			return Palette.RARITY_COMMON_BORDER
		"アンコモン":
			return Palette.RARITY_UNCOMMON_BORDER
		"レア":
			return Palette.RARITY_RARE_BORDER
		"ぬし":
			return Palette.GOLD_BRIGHT
		_:
			return Palette.GOLD


static func is_rare_or_boss(fish: Dictionary) -> bool:
	var rarity := String(fish.get("rarity", ""))
	return rarity == "レア" or rarity == "ぬし" or bool(fish.get("boss", false))
