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
		"fish_no": "No.001",
		"preferred_bait": "アミエビ",
		"visual_scale": 0.82,
		"line_anchor_x": 0.455,
		"line_anchor_y": 0.02,
		"motion": {"wave_amp": 0.026, "wave_freq": 4.8, "dash_shift": 0.040, "turn_shift": 0.060, "dive_shift": 0.020, "jitter": 0.006, "depth_bias": 0.0},
		"action_profile": {"dash": 0.22, "dive": 0.08, "turn": 0.45, "rest": 0.25},
		"action_messages": {"dash": "アジが小さく走った！ テンションを保とう！", "dive": "アジが少し潜る！ 焦らず合わせよう。", "turn": "アジが素早く向きを変えた！", "rest": "アジの動きが緩んだ。巻き上げよう！"},
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
		"fish_no": "No.002",
		"preferred_bait": "オキアミ",
		"visual_scale": 0.96,
		"line_anchor_x": 0.420,
		"line_anchor_y": 0.04,
		"motion": {"wave_amp": 0.018, "wave_freq": 2.6, "dash_shift": 0.038, "turn_shift": 0.040, "dive_shift": 0.050, "jitter": 0.002, "depth_bias": 0.020},
		"action_profile": {"dash": 0.20, "dive": 0.40, "turn": 0.22, "rest": 0.18},
		"action_messages": {"dash": "メジナが根へ走った！ 無理に巻かず耐えよう！", "dive": "メジナが深く潜る！ 糸を出して耐えよう！", "turn": "メジナが足元で反転した。テンション注意！", "rest": "メジナの抵抗が弱まった。今が巻き時だ！"},
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
		"fish_no": "No.003",
		"preferred_bait": "イソメ",
		"visual_scale": 0.78,
		"line_anchor_x": 0.400,
		"line_anchor_y": 0.02,
		"motion": {"wave_amp": 0.010, "wave_freq": 1.7, "dash_shift": 0.030, "turn_shift": 0.026, "dive_shift": 0.065, "jitter": 0.002, "depth_bias": 0.060},
		"action_profile": {"dash": 0.36, "dive": 0.34, "turn": 0.14, "rest": 0.16},
		"action_messages": {"dash": "カサゴが岩陰へ突っ込む！ 竿を立てて耐えよう！", "dive": "カサゴが底へ張り付く！ 糸を出して粘ろう！", "turn": "カサゴが短く向きを変えた。", "rest": "カサゴが浮いた。巻き上げるチャンス！"},
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
		"fish_no": "No.004",
		"preferred_bait": "オキアミ",
		"visual_scale": 0.94,
		"line_anchor_x": 0.440,
		"line_anchor_y": 0.02,
		"motion": {"wave_amp": 0.020, "wave_freq": 3.0, "dash_shift": 0.055, "turn_shift": 0.040, "dive_shift": 0.034, "jitter": 0.003, "depth_bias": 0.010},
		"action_profile": {"dash": 0.38, "dive": 0.20, "turn": 0.22, "rest": 0.20},
		"action_messages": {"dash": "イサキが長く走る！ 巻きすぎず追従しよう！", "dive": "イサキが沖の根へ潜る！", "turn": "イサキが群れのように向きを変えた。", "rest": "イサキの走りが止まった。巻き上げよう！"},
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
		"fish_no": "No.005",
		"preferred_bait": "小魚",
		"visual_scale": 0.98,
		"line_anchor_x": 0.455,
		"line_anchor_y": 0.01,
		"motion": {"wave_amp": 0.030, "wave_freq": 5.2, "dash_shift": 0.080, "turn_shift": 0.045, "dive_shift": 0.022, "jitter": 0.005, "depth_bias": -0.010},
		"action_profile": {"dash": 0.52, "dive": 0.10, "turn": 0.22, "rest": 0.16},
		"action_messages": {"dash": "サバが横へ一気に走った！ ラインを出して耐えよう！", "dive": "サバが少し潜る！ 速度に注意！", "turn": "サバが高速で反転した！", "rest": "サバの走りが緩んだ。巻き時だ！"},
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
		"fish_no": "No.006",
		"preferred_bait": "小魚",
		"visual_scale": 1.10,
		"line_anchor_x": 0.445,
		"line_anchor_y": 0.00,
		"motion": {"wave_amp": 0.020, "wave_freq": 2.8, "dash_shift": 0.065, "turn_shift": 0.070, "dive_shift": 0.018, "jitter": 0.002, "depth_bias": -0.030},
		"action_profile": {"dash": 0.38, "dive": 0.12, "turn": 0.36, "rest": 0.14},
		"action_messages": {"dash": "スズキが水面近くを長く走る！", "dive": "スズキが潮目の下へ潜る！", "turn": "スズキが大きく反転した！ テンションの変化に注意！", "rest": "スズキの動きが止まった。距離を詰めよう！"},
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
		"fish_no": "No.007",
		"preferred_bait": "オキアミ",
		"visual_scale": 1.08,
		"line_anchor_x": 0.420,
		"line_anchor_y": 0.04,
		"motion": {"wave_amp": 0.013, "wave_freq": 2.0, "dash_shift": 0.040, "turn_shift": 0.030, "dive_shift": 0.058, "jitter": 0.001, "depth_bias": 0.025},
		"action_profile": {"dash": 0.24, "dive": 0.38, "turn": 0.18, "rest": 0.20},
		"action_messages": {"dash": "マダイが重く首を振る！ 無理に巻かず耐えよう！", "dive": "マダイが底へ向かう！ 糸を出して粘ろう！", "turn": "マダイがゆっくり反転した。", "rest": "マダイの重みが抜けた。巻き上げよう！"},
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
		"fish_no": "No.008",
		"preferred_bait": "小魚",
		"visual_scale": 1.04,
		"line_anchor_x": 0.430,
		"line_anchor_y": 0.05,
		"motion": {"wave_amp": 0.008, "wave_freq": 1.5, "dash_shift": 0.055, "turn_shift": 0.022, "dive_shift": 0.060, "jitter": 0.001, "depth_bias": 0.070},
		"action_profile": {"dash": 0.30, "dive": 0.42, "turn": 0.12, "rest": 0.16},
		"action_messages": {"dash": "ヒラメが底から横へ走った！", "dive": "ヒラメが砂地へ張り付く！ 焦らず耐えよう！", "turn": "ヒラメが低く向きを変えた。", "rest": "ヒラメが浮いた。巻き上げるチャンス！"},
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
		"fish_no": "No.009",
		"preferred_bait": "アサリ",
		"visual_scale": 0.78,
		"line_anchor_x": 0.380,
		"line_anchor_y": 0.00,
		"motion": {"wave_amp": 0.024, "wave_freq": 6.2, "dash_shift": 0.034, "turn_shift": 0.070, "dive_shift": 0.020, "jitter": 0.012, "depth_bias": 0.010},
		"action_profile": {"dash": 0.18, "dive": 0.12, "turn": 0.50, "rest": 0.20},
		"action_messages": {"dash": "カワハギが細かく逃げた！ テンションを揺さぶられる！", "dive": "カワハギが足元へ潜る！", "turn": "カワハギが小刻みに方向転換した！", "rest": "カワハギの動きが止まった。巻き上げよう！"},
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
		"fish_no": "No.028",
		"preferred_bait": "岩ガニ",
		"visual_scale": 1.18,
		"line_anchor_x": 0.430,
		"line_anchor_y": 0.03,
		"motion": {"wave_amp": 0.016, "wave_freq": 2.2, "dash_shift": 0.060, "turn_shift": 0.045, "dive_shift": 0.070, "jitter": 0.002, "depth_bias": 0.030},
		"action_profile": {"dash": 0.34, "dive": 0.26, "turn": 0.20, "rest": 0.20},
		"action_messages": {"dash": "ぬしが激しく突進した！ 巻くのを止めよう！", "dive": "ぬしが海底へ潜る！ 糸を出して耐えよう！", "turn": "ぬしが急反転！ テンションの変化に注意！", "rest": "ぬしの動きが鈍った。今が巻き時だ！"},
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
