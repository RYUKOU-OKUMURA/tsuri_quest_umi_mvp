extends Node

const MAX_LEVEL: int = 10
const BOSS_UNLOCK_LEVEL: int = 5

const FISH: Dictionary = {
	"aji":
	{
		"id": "aji",
		"name": "アジ",
		"rarity": "コモン",
		"min_level": 1,
		"boss": false,
		"weight": 32.0,
		"size_min": 18.0,
		"size_max": 36.0,
		"sell_price": 120,
		"food_exp": 20,
		"stamina": 42.0,
		"power": 0.62,
		"speed": 1.10,
		"start_distance": 20.0,
		"start_depth": 7.0,
		"color": "#9cc9d8",
		"habitat": "港内・堤防周り",
		"behavior": "小刻みに方向転換する。初心者向け。",
	},
	"mejina":
	{
		"id": "mejina",
		"name": "メジナ",
		"rarity": "コモン",
		"min_level": 1,
		"boss": false,
		"weight": 24.0,
		"size_min": 24.0,
		"size_max": 46.0,
		"sell_price": 190,
		"food_exp": 28,
		"stamina": 58.0,
		"power": 0.82,
		"speed": 0.88,
		"start_distance": 23.0,
		"start_depth": 9.0,
		"color": "#4b6875",
		"habitat": "磯・消波ブロック周り",
		"behavior": "根へ向かって潜る。糸を出す判断が必要。",
	},
	"kasago":
	{
		"id": "kasago",
		"name": "カサゴ",
		"rarity": "コモン",
		"min_level": 1,
		"boss": false,
		"weight": 20.0,
		"size_min": 17.0,
		"size_max": 34.0,
		"sell_price": 210,
		"food_exp": 30,
		"stamina": 50.0,
		"power": 0.75,
		"speed": 0.64,
		"start_distance": 19.0,
		"start_depth": 12.0,
		"color": "#b85c42",
		"habitat": "岩礁・海底付近",
		"behavior": "底へ張り付く。短く強い突進を行う。",
	},
	"isaki":
	{
		"id": "isaki",
		"name": "イサキ",
		"rarity": "アンコモン",
		"min_level": 2,
		"boss": false,
		"weight": 15.0,
		"size_min": 26.0,
		"size_max": 52.0,
		"sell_price": 320,
		"food_exp": 42,
		"stamina": 72.0,
		"power": 0.98,
		"speed": 0.95,
		"start_distance": 27.0,
		"start_depth": 13.0,
		"color": "#8da39d",
		"habitat": "沖の岩礁帯",
		"behavior": "一定間隔で長く走る。体力管理が重要。",
	},
	"saba":
	{
		"id": "saba",
		"name": "サバ",
		"rarity": "アンコモン",
		"min_level": 3,
		"boss": false,
		"weight": 9.0,
		"size_min": 30.0,
		"size_max": 58.0,
		"sell_price": 390,
		"food_exp": 50,
		"stamina": 84.0,
		"power": 1.05,
		"speed": 1.35,
		"start_distance": 30.0,
		"start_depth": 10.0,
		"color": "#6a91a5",
		"habitat": "港外・潮通しのよい場所",
		"behavior": "横方向へ高速で走り続ける。",
	},
	"suzuki":
	{
		"id": "suzuki",
		"name": "スズキ",
		"rarity": "アンコモン",
		"min_level": 3,
		"boss": false,
		"weight": 8.0,
		"size_min": 42.0,
		"size_max": 78.0,
		"sell_price": 520,
		"food_exp": 62,
		"stamina": 92.0,
		"power": 1.12,
		"speed": 1.12,
		"start_distance": 33.0,
		"start_depth": 8.0,
		"color": "#9fa69a",
		"habitat": "河口・港外の潮目",
		"behavior": "水面近くで反転し、長く走る。",
	},
	"madai":
	{
		"id": "madai",
		"name": "マダイ",
		"rarity": "レア",
		"min_level": 4,
		"boss": false,
		"weight": 5.0,
		"size_min": 38.0,
		"size_max": 72.0,
		"sell_price": 760,
		"food_exp": 86,
		"stamina": 118.0,
		"power": 1.24,
		"speed": 0.96,
		"start_distance": 35.0,
		"start_depth": 16.0,
		"color": "#d77b76",
		"habitat": "沖の岩礁・砂地の境目",
		"behavior": "重く首を振りながら底へ向かう。",
	},
	"hirame":
	{
		"id": "hirame",
		"name": "ヒラメ",
		"rarity": "レア",
		"min_level": 4,
		"boss": false,
		"weight": 4.5,
		"size_min": 36.0,
		"size_max": 70.0,
		"sell_price": 820,
		"food_exp": 90,
		"stamina": 110.0,
		"power": 1.18,
		"speed": 0.78,
		"start_distance": 31.0,
		"start_depth": 14.0,
		"color": "#7b6b42",
		"habitat": "砂地・かけあがり",
		"behavior": "底に張り付き、急に横へ走る。",
	},
	"kawahagi":
	{
		"id": "kawahagi",
		"name": "カワハギ",
		"rarity": "アンコモン",
		"min_level": 2,
		"boss": false,
		"weight": 10.0,
		"size_min": 18.0,
		"size_max": 34.0,
		"sell_price": 360,
		"food_exp": 46,
		"stamina": 68.0,
		"power": 0.88,
		"speed": 1.02,
		"start_distance": 24.0,
		"start_depth": 11.0,
		"color": "#8d7b55",
		"habitat": "堤防際・砂まじりの岩場",
		"behavior": "細かく逃げ回り、テンションを揺さぶる。",
	},
	"boss_kurodai":
	{
		"id": "boss_kurodai",
		"name": "港のぬし・大岩クロダイ",
		"rarity": "ぬし",
		"min_level": 5,
		"boss": true,
		"weight": 1.0,
		"size_min": 72.0,
		"size_max": 94.0,
		"sell_price": 2500,
		"food_exp": 180,
		"stamina": 190.0,
		"power": 1.55,
		"speed": 1.08,
		"start_distance": 38.0,
		"start_depth": 18.0,
		"color": "#394956",
		"habitat": "港口の大岩周辺",
		"behavior": "潜水・反転・連続突進を使う港のぬし。",
	},
}

const RECIPES: Dictionary = {
	"salt_grill":
	{
		"id": "salt_grill",
		"name": "塩焼き",
		"unlock_level": 1,
		"exp_multiplier": 1.0,
		"allowed_fish": ["aji", "mejina", "kasago", "isaki", "saba", "suzuki", "madai", "hirame", "kawahagi", "boss_kurodai"],
		"description": "素材の味を活かす基本料理。",
		"buff_stat": "max_energy",
		"buff_value": 0.05,
		"buff_text": "次の釣行で最大体力 +5%",
	},
	"sashimi":
	{
		"id": "sashimi",
		"name": "刺身",
		"unlock_level": 2,
		"exp_multiplier": 1.2,
		"allowed_fish": ["aji", "mejina", "isaki", "saba", "suzuki", "madai", "hirame", "kawahagi", "boss_kurodai"],
		"description": "鮮度を活かした一皿。アワセの猶予が伸びる。",
		"buff_stat": "bite_window",
		"buff_value": 0.35,
		"buff_text": "次の釣行でアワセ猶予 +0.35秒",
	},
	"simmered":
	{
		"id": "simmered",
		"name": "煮付け",
		"unlock_level": 3,
		"exp_multiplier": 1.35,
		"allowed_fish": ["mejina", "kasago", "isaki", "madai", "hirame", "kawahagi", "boss_kurodai"],
		"description": "じっくり煮込んだ料理。安全なテンション域が広がる。",
		"buff_stat": "safe_range",
		"buff_value": 0.05,
		"buff_text": "次の釣行で安全テンション域 +5%",
	},
	"soup":
	{
		"id": "soup",
		"name": "つみれ汁",
		"unlock_level": 4,
		"exp_multiplier": 1.5,
		"allowed_fish": ["aji", "mejina", "kasago", "isaki", "saba", "suzuki", "madai", "hirame", "kawahagi", "boss_kurodai"],
		"description": "身体が温まる汁物。体力回復が速くなる。",
		"buff_stat": "energy_regen",
		"buff_value": 0.18,
		"buff_text": "次の釣行で体力回復 +18%",
	},
	"fry":
	{
		"id": "fry",
		"name": "魚フライ",
		"unlock_level": 5,
		"exp_multiplier": 1.6,
		"allowed_fish": ["aji", "isaki", "saba", "suzuki", "madai", "hirame", "kawahagi"],
		"description": "食べ応えのある揚げ物。巻き上げ力が増す。",
		"buff_stat": "reel_power",
		"buff_value": 0.10,
		"buff_text": "次の釣行で巻力 +10%",
	},
}

const RODS: Dictionary = {
	"starter":
	{
		"id": "starter",
		"name": "港の入門竿",
		"price": 0,
		"reel_multiplier": 1.0,
		"line_limit_bonus": 0.0,
		"technique_bonus": 0,
		"description": "扱いやすい標準装備。",
	},
	"iso":
	{
		"id": "iso",
		"name": "磯竿・潮風",
		"price": 850,
		"reel_multiplier": 1.12,
		"line_limit_bonus": 0.05,
		"technique_bonus": 1,
		"description": "粘りがあり、強い引きにも耐える。",
	},
	"offshore":
	{
		"id": "offshore",
		"name": "外海竿・青嵐",
		"price": 2600,
		"reel_multiplier": 1.30,
		"line_limit_bonus": 0.10,
		"technique_bonus": 2,
		"description": "ぬしとの長期戦を想定した上位竿。",
	},
}

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func get_fish(fish_id: String) -> Dictionary:
	if not FISH.has(fish_id):
		return {}
	return FISH[fish_id].duplicate(true)


func get_recipe(recipe_id: String) -> Dictionary:
	if not RECIPES.has(recipe_id):
		return {}
	return RECIPES[recipe_id].duplicate(true)


func get_rod(rod_id: String) -> Dictionary:
	if not RODS.has(rod_id):
		return {}
	return RODS[rod_id].duplicate(true)


func get_all_fish_ids() -> Array[String]:
	var ids: Array[String] = []
	for fish_id in FISH.keys():
		ids.append(String(fish_id))
	return ids


func get_all_rod_ids() -> Array[String]:
	var ids: Array[String] = []
	for rod_id in RODS.keys():
		ids.append(String(rod_id))
	return ids


func get_recipes_for_fish(fish_id: String, player_level: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for recipe_id in RECIPES.keys():
		var recipe: Dictionary = RECIPES[recipe_id]
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


func roll_normal_fish(player_level: int) -> Dictionary:
	var candidate_ids: Array[String] = []
	var total_weight := 0.0
	for fish_id_variant in FISH.keys():
		var fish_id := String(fish_id_variant)
		var fish: Dictionary = FISH[fish_id]
		if bool(fish["boss"]):
			continue
		if int(fish["min_level"]) > player_level:
			continue
		candidate_ids.append(fish_id)
		total_weight += float(fish["weight"])

	if candidate_ids.is_empty():
		return get_fish("aji")

	var pick := _rng.randf_range(0.0, total_weight)
	var running := 0.0
	for fish_id in candidate_ids:
		running += float(FISH[fish_id]["weight"])
		if pick <= running:
			return get_fish(fish_id)
	return get_fish(candidate_ids.back())


func roll_fish_size(fish: Dictionary) -> float:
	return snappedf(_rng.randf_range(float(fish["size_min"]), float(fish["size_max"])), 0.1)


func recipe_exp(fish_id: String, recipe_id: String) -> int:
	var fish := get_fish(fish_id)
	var recipe := get_recipe(recipe_id)
	if fish.is_empty() or recipe.is_empty():
		return 0
	return int(round(float(fish["food_exp"]) * float(recipe["exp_multiplier"])))
