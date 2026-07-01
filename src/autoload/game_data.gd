extends Node

const MAX_LEVEL: int = 10
const BOSS_UNLOCK_LEVEL: int = 5
const DEFAULT_FISHING_SPOT_ID := "harbor_pier"
const BOSS_FISHING_SPOT_ID := "harbor_boulder"
const NO_BOAT_RANK := 0

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
	"iwashi":
	{
		"id": "iwashi",
		"name": "イワシ",
		"rarity": "コモン",
		"min_level": 1,
		"boss": false,
		"weight": 26.0,
		"size_min": 14.0,
		"size_max": 24.0,
		"sell_price": 90,
		"food_exp": 16,
		"stamina": 34.0,
		"power": 0.48,
		"speed": 1.28,
		"start_distance": 18.0,
		"start_depth": 6.0,
		"color": "#8fb7c8",
		"habitat": "港内・表層の群れ",
		"behavior": "群れで小刻みに泳ぎ、細かく向きを変える。",
		"fish_no": "No.010",
		"preferred_bait": "アミエビ",
		"visual_scale": 0.68,
		"line_anchor_x": 0.455,
		"line_anchor_y": 0.00,
		"motion": {"wave_amp": 0.028, "wave_freq": 6.0, "dash_shift": 0.036, "turn_shift": 0.070, "dive_shift": 0.014, "jitter": 0.012, "depth_bias": -0.030},
		"action_profile": {"dash": 0.20, "dive": 0.06, "turn": 0.56, "rest": 0.18},
		"action_messages": {"dash": "イワシが群れに戻ろうと走る！", "dive": "イワシが少し潜った。", "turn": "イワシが小刻みに反転した！", "rest": "イワシの動きが緩んだ。巻き上げよう！"},
	},
	"shirogisu":
	{
		"id": "shirogisu",
		"name": "シロギス",
		"rarity": "コモン",
		"min_level": 1,
		"boss": false,
		"weight": 22.0,
		"size_min": 16.0,
		"size_max": 29.0,
		"sell_price": 130,
		"food_exp": 22,
		"stamina": 40.0,
		"power": 0.58,
		"speed": 1.05,
		"start_distance": 21.0,
		"start_depth": 8.0,
		"color": "#d8c29a",
		"habitat": "砂浜・浅いかけあがり",
		"behavior": "砂地を軽く走る。引きは素直で扱いやすい。",
		"fish_no": "No.011",
		"preferred_bait": "イソメ",
		"visual_scale": 0.72,
		"line_anchor_x": 0.455,
		"line_anchor_y": 0.01,
		"motion": {"wave_amp": 0.020, "wave_freq": 3.8, "dash_shift": 0.038, "turn_shift": 0.045, "dive_shift": 0.024, "jitter": 0.004, "depth_bias": 0.010},
		"action_profile": {"dash": 0.28, "dive": 0.18, "turn": 0.30, "rest": 0.24},
		"action_messages": {"dash": "シロギスが砂地を軽く走った！", "dive": "シロギスが砂地へ潜る！", "turn": "シロギスが向きを変えた。", "rest": "シロギスの動きが止まった。巻き上げよう！"},
	},
	"mebaru":
	{
		"id": "mebaru",
		"name": "メバル",
		"rarity": "コモン",
		"min_level": 2,
		"boss": false,
		"weight": 18.0,
		"size_min": 18.0,
		"size_max": 32.0,
		"sell_price": 180,
		"food_exp": 29,
		"stamina": 52.0,
		"power": 0.74,
		"speed": 0.78,
		"start_distance": 20.0,
		"start_depth": 10.0,
		"color": "#9b4c38",
		"habitat": "岩場・藻場の陰",
		"behavior": "岩陰へ潜り、短く粘る。",
		"fish_no": "No.012",
		"preferred_bait": "イソメ",
		"visual_scale": 0.76,
		"line_anchor_x": 0.405,
		"line_anchor_y": 0.02,
		"motion": {"wave_amp": 0.012, "wave_freq": 2.0, "dash_shift": 0.032, "turn_shift": 0.030, "dive_shift": 0.055, "jitter": 0.002, "depth_bias": 0.045},
		"action_profile": {"dash": 0.28, "dive": 0.36, "turn": 0.18, "rest": 0.18},
		"action_messages": {"dash": "メバルが岩陰へ走った！", "dive": "メバルが下へ潜る！ 根に入られないよう耐えよう！", "turn": "メバルが短く向きを変えた。", "rest": "メバルが浮いた。巻き上げよう！"},
	},
	"ainame":
	{
		"id": "ainame",
		"name": "アイナメ",
		"rarity": "アンコモン",
		"min_level": 2,
		"boss": false,
		"weight": 14.0,
		"size_min": 28.0,
		"size_max": 48.0,
		"sell_price": 300,
		"food_exp": 42,
		"stamina": 70.0,
		"power": 0.95,
		"speed": 0.72,
		"start_distance": 24.0,
		"start_depth": 13.0,
		"color": "#7a6b3e",
		"habitat": "岩礁・消波ブロックの底",
		"behavior": "重く底へ向かう。根に潜る前に止めたい。",
		"fish_no": "No.013",
		"preferred_bait": "イソメ",
		"visual_scale": 0.92,
		"line_anchor_x": 0.425,
		"line_anchor_y": 0.03,
		"motion": {"wave_amp": 0.010, "wave_freq": 1.8, "dash_shift": 0.034, "turn_shift": 0.026, "dive_shift": 0.065, "jitter": 0.001, "depth_bias": 0.060},
		"action_profile": {"dash": 0.24, "dive": 0.46, "turn": 0.12, "rest": 0.18},
		"action_messages": {"dash": "アイナメが根へ走る！ 竿を立てて耐えよう！", "dive": "アイナメが底へ潜る！ 糸を出して粘ろう！", "turn": "アイナメが重く向きを変えた。", "rest": "アイナメが浮いた。巻き上げるチャンス！"},
	},
	"bora":
	{
		"id": "bora",
		"name": "ボラ",
		"rarity": "アンコモン",
		"min_level": 2,
		"boss": false,
		"weight": 12.0,
		"size_min": 38.0,
		"size_max": 70.0,
		"sell_price": 260,
		"food_exp": 38,
		"stamina": 82.0,
		"power": 0.92,
		"speed": 1.18,
		"start_distance": 29.0,
		"start_depth": 7.0,
		"color": "#9aa998",
		"habitat": "港内・河口の表層",
		"behavior": "水面近くを大きく反転しながら走る。",
		"fish_no": "No.014",
		"preferred_bait": "練りエサ",
		"visual_scale": 1.02,
		"line_anchor_x": 0.445,
		"line_anchor_y": 0.00,
		"motion": {"wave_amp": 0.024, "wave_freq": 3.4, "dash_shift": 0.060, "turn_shift": 0.075, "dive_shift": 0.015, "jitter": 0.004, "depth_bias": -0.040},
		"action_profile": {"dash": 0.32, "dive": 0.08, "turn": 0.42, "rest": 0.18},
		"action_messages": {"dash": "ボラが水面近くを走った！", "dive": "ボラが少し沈んだ。", "turn": "ボラが大きく反転した！ テンション注意！", "rest": "ボラの動きが鈍った。距離を詰めよう！"},
	},
	"kamasu":
	{
		"id": "kamasu",
		"name": "カマス",
		"rarity": "アンコモン",
		"min_level": 3,
		"boss": false,
		"weight": 10.0,
		"size_min": 28.0,
		"size_max": 48.0,
		"sell_price": 340,
		"food_exp": 46,
		"stamina": 66.0,
		"power": 0.86,
		"speed": 1.48,
		"start_distance": 30.0,
		"start_depth": 8.0,
		"color": "#9fb2b2",
		"habitat": "港外・常夜灯周り",
		"behavior": "細長い体で鋭く横へ走る。",
		"fish_no": "No.015",
		"preferred_bait": "小魚",
		"visual_scale": 0.86,
		"line_anchor_x": 0.470,
		"line_anchor_y": 0.00,
		"motion": {"wave_amp": 0.027, "wave_freq": 5.6, "dash_shift": 0.082, "turn_shift": 0.050, "dive_shift": 0.018, "jitter": 0.006, "depth_bias": -0.020},
		"action_profile": {"dash": 0.56, "dive": 0.08, "turn": 0.22, "rest": 0.14},
		"action_messages": {"dash": "カマスが鋭く横へ走った！", "dive": "カマスが少し潜る！", "turn": "カマスが素早く向きを変えた！", "rest": "カマスの走りが止まった。巻き上げよう！"},
	},
	"kochi":
	{
		"id": "kochi",
		"name": "コチ",
		"rarity": "アンコモン",
		"min_level": 3,
		"boss": false,
		"weight": 8.0,
		"size_min": 35.0,
		"size_max": 62.0,
		"sell_price": 470,
		"food_exp": 58,
		"stamina": 88.0,
		"power": 1.02,
		"speed": 0.70,
		"start_distance": 27.0,
		"start_depth": 14.0,
		"color": "#7f6a48",
		"habitat": "砂地・かけあがりの底",
		"behavior": "底に張り付き、突然横へ走る。",
		"fish_no": "No.016",
		"preferred_bait": "小魚",
		"visual_scale": 1.00,
		"line_anchor_x": 0.430,
		"line_anchor_y": 0.04,
		"motion": {"wave_amp": 0.008, "wave_freq": 1.5, "dash_shift": 0.052, "turn_shift": 0.020, "dive_shift": 0.066, "jitter": 0.001, "depth_bias": 0.075},
		"action_profile": {"dash": 0.32, "dive": 0.42, "turn": 0.10, "rest": 0.16},
		"action_messages": {"dash": "コチが砂地から横へ走った！", "dive": "コチが底へ張り付く！ 焦らず耐えよう！", "turn": "コチが低く向きを変えた。", "rest": "コチが浮いた。巻き上げよう！"},
	},
	"tachiuo":
	{
		"id": "tachiuo",
		"name": "タチウオ",
		"rarity": "レア",
		"min_level": 4,
		"boss": false,
		"weight": 6.0,
		"size_min": 70.0,
		"size_max": 115.0,
		"sell_price": 680,
		"food_exp": 78,
		"stamina": 90.0,
		"power": 1.08,
		"speed": 1.20,
		"start_distance": 34.0,
		"start_depth": 15.0,
		"color": "#b7c8d3",
		"habitat": "沖の深場・夜の港外",
		"behavior": "銀色の体をくねらせ、上下に鋭く動く。",
		"fish_no": "No.017",
		"preferred_bait": "小魚",
		"visual_scale": 1.04,
		"line_anchor_x": 0.465,
		"line_anchor_y": 0.00,
		"motion": {"wave_amp": 0.032, "wave_freq": 4.4, "dash_shift": 0.060, "turn_shift": 0.050, "dive_shift": 0.050, "jitter": 0.005, "depth_bias": 0.030},
		"action_profile": {"dash": 0.34, "dive": 0.28, "turn": 0.24, "rest": 0.14},
		"action_messages": {"dash": "タチウオが銀色の体で走った！", "dive": "タチウオが深場へ沈む！", "turn": "タチウオが鋭く反転した！", "rest": "タチウオの動きが止まった。巻き上げよう！"},
	},
	"ishidai":
	{
		"id": "ishidai",
		"name": "イシダイ",
		"rarity": "レア",
		"min_level": 4,
		"boss": false,
		"weight": 5.5,
		"size_min": 35.0,
		"size_max": 62.0,
		"sell_price": 780,
		"food_exp": 88,
		"stamina": 118.0,
		"power": 1.30,
		"speed": 0.82,
		"start_distance": 32.0,
		"start_depth": 16.0,
		"color": "#5c6268",
		"habitat": "磯・岩礁の深み",
		"behavior": "強い歯で根周りへ突っ込み、重く粘る。",
		"fish_no": "No.018",
		"preferred_bait": "貝",
		"visual_scale": 0.98,
		"line_anchor_x": 0.420,
		"line_anchor_y": 0.03,
		"motion": {"wave_amp": 0.012, "wave_freq": 2.0, "dash_shift": 0.050, "turn_shift": 0.030, "dive_shift": 0.060, "jitter": 0.001, "depth_bias": 0.045},
		"action_profile": {"dash": 0.34, "dive": 0.34, "turn": 0.12, "rest": 0.20},
		"action_messages": {"dash": "イシダイが岩場へ突っ込む！", "dive": "イシダイが深く潜る！ 糸を出して耐えよう！", "turn": "イシダイが重く反転した。", "rest": "イシダイの抵抗が弱まった。巻き時だ！"},
	},
	"akahata":
	{
		"id": "akahata",
		"name": "アカハタ",
		"rarity": "レア",
		"min_level": 4,
		"boss": false,
		"weight": 5.0,
		"size_min": 28.0,
		"size_max": 48.0,
		"sell_price": 720,
		"food_exp": 82,
		"stamina": 100.0,
		"power": 1.12,
		"speed": 0.78,
		"start_distance": 29.0,
		"start_depth": 17.0,
		"color": "#c85a34",
		"habitat": "南の岩礁・サンゴ根",
		"behavior": "岩陰へ戻ろうとする赤い根魚。",
		"fish_no": "No.019",
		"preferred_bait": "小魚",
		"visual_scale": 0.88,
		"line_anchor_x": 0.410,
		"line_anchor_y": 0.03,
		"motion": {"wave_amp": 0.010, "wave_freq": 1.8, "dash_shift": 0.042, "turn_shift": 0.028, "dive_shift": 0.064, "jitter": 0.001, "depth_bias": 0.070},
		"action_profile": {"dash": 0.30, "dive": 0.42, "turn": 0.12, "rest": 0.16},
		"action_messages": {"dash": "アカハタが岩陰へ走った！", "dive": "アカハタが根へ潜る！", "turn": "アカハタが短く反転した。", "rest": "アカハタが浮いた。巻き上げよう！"},
	},
	"fuefukidai":
	{
		"id": "fuefukidai",
		"name": "フエフキダイ",
		"rarity": "レア",
		"min_level": 5,
		"boss": false,
		"weight": 4.2,
		"size_min": 38.0,
		"size_max": 72.0,
		"sell_price": 860,
		"food_exp": 96,
		"stamina": 126.0,
		"power": 1.22,
		"speed": 0.92,
		"start_distance": 35.0,
		"start_depth": 18.0,
		"color": "#d3928d",
		"habitat": "南の沖根・砂地の境目",
		"behavior": "重く首を振りながら沖へ走る。",
		"fish_no": "No.020",
		"preferred_bait": "オキアミ",
		"visual_scale": 1.06,
		"line_anchor_x": 0.420,
		"line_anchor_y": 0.04,
		"motion": {"wave_amp": 0.014, "wave_freq": 2.1, "dash_shift": 0.046, "turn_shift": 0.032, "dive_shift": 0.058, "jitter": 0.001, "depth_bias": 0.040},
		"action_profile": {"dash": 0.30, "dive": 0.34, "turn": 0.16, "rest": 0.20},
		"action_messages": {"dash": "フエフキダイが沖へ走る！", "dive": "フエフキダイが底へ向かう！", "turn": "フエフキダイが重く反転した。", "rest": "フエフキダイの動きが鈍った。巻き時だ！"},
	},
	"aobudai":
	{
		"id": "aobudai",
		"name": "アオブダイ",
		"rarity": "レア",
		"min_level": 5,
		"boss": false,
		"weight": 3.8,
		"size_min": 45.0,
		"size_max": 80.0,
		"sell_price": 900,
		"food_exp": 104,
		"stamina": 132.0,
		"power": 1.18,
		"speed": 0.86,
		"start_distance": 34.0,
		"start_depth": 12.0,
		"color": "#2e9db0",
		"habitat": "サンゴ礁・浅い岩礁帯",
		"behavior": "大きな体でゆっくり反転し、岩場へ寄る。",
		"fish_no": "No.021",
		"preferred_bait": "貝",
		"visual_scale": 1.10,
		"line_anchor_x": 0.405,
		"line_anchor_y": 0.03,
		"motion": {"wave_amp": 0.012, "wave_freq": 1.9, "dash_shift": 0.038, "turn_shift": 0.048, "dive_shift": 0.050, "jitter": 0.001, "depth_bias": 0.010},
		"action_profile": {"dash": 0.20, "dive": 0.30, "turn": 0.30, "rest": 0.20},
		"action_messages": {"dash": "アオブダイが重く走る！", "dive": "アオブダイが岩場へ潜る！", "turn": "アオブダイが大きく反転した。", "rest": "アオブダイの動きが止まった。巻き上げよう！"},
	},
	"kanpachi":
	{
		"id": "kanpachi",
		"name": "カンパチ",
		"rarity": "レア",
		"min_level": 6,
		"boss": false,
		"weight": 3.3,
		"size_min": 55.0,
		"size_max": 95.0,
		"sell_price": 1050,
		"food_exp": 118,
		"stamina": 142.0,
		"power": 1.28,
		"speed": 1.35,
		"start_distance": 40.0,
		"start_depth": 14.0,
		"color": "#7f9aa0",
		"habitat": "沖の潮目・回遊ルート",
		"behavior": "青物らしく長く横へ走る。",
		"fish_no": "No.022",
		"preferred_bait": "小魚",
		"visual_scale": 1.14,
		"line_anchor_x": 0.445,
		"line_anchor_y": 0.01,
		"motion": {"wave_amp": 0.026, "wave_freq": 4.8, "dash_shift": 0.088, "turn_shift": 0.048, "dive_shift": 0.030, "jitter": 0.004, "depth_bias": 0.000},
		"action_profile": {"dash": 0.56, "dive": 0.14, "turn": 0.16, "rest": 0.14},
		"action_messages": {"dash": "カンパチが沖へ一気に走る！ ラインを出して耐えよう！", "dive": "カンパチが潮目の下へ潜る！", "turn": "カンパチが高速で向きを変えた！", "rest": "カンパチの走りが緩んだ。巻き時だ！"},
	},
	"buri":
	{
		"id": "buri",
		"name": "ブリ",
		"rarity": "レア",
		"min_level": 6,
		"boss": false,
		"weight": 3.0,
		"size_min": 65.0,
		"size_max": 110.0,
		"sell_price": 1180,
		"food_exp": 130,
		"stamina": 158.0,
		"power": 1.38,
		"speed": 1.20,
		"start_distance": 42.0,
		"start_depth": 15.0,
		"color": "#6f9097",
		"habitat": "外海・潮通しのよい沖",
		"behavior": "重い体で長く走り、巻き上げを拒む。",
		"fish_no": "No.023",
		"preferred_bait": "小魚",
		"visual_scale": 1.18,
		"line_anchor_x": 0.440,
		"line_anchor_y": 0.01,
		"motion": {"wave_amp": 0.020, "wave_freq": 3.4, "dash_shift": 0.078, "turn_shift": 0.040, "dive_shift": 0.038, "jitter": 0.002, "depth_bias": 0.010},
		"action_profile": {"dash": 0.50, "dive": 0.22, "turn": 0.12, "rest": 0.16},
		"action_messages": {"dash": "ブリが外海へ走る！ 無理に止めず耐えよう！", "dive": "ブリが深く沈む！", "turn": "ブリが重く向きを変えた。", "rest": "ブリの走りが止まった。巻き上げよう！"},
	},
	"katsuo":
	{
		"id": "katsuo",
		"name": "カツオ",
		"rarity": "レア",
		"min_level": 7,
		"boss": false,
		"weight": 2.8,
		"size_min": 45.0,
		"size_max": 78.0,
		"sell_price": 1250,
		"food_exp": 136,
		"stamina": 136.0,
		"power": 1.22,
		"speed": 1.60,
		"start_distance": 44.0,
		"start_depth": 12.0,
		"color": "#526d8c",
		"habitat": "外海表層・潮目",
		"behavior": "表層を高速で走り続ける。",
		"fish_no": "No.024",
		"preferred_bait": "小魚",
		"visual_scale": 1.06,
		"line_anchor_x": 0.455,
		"line_anchor_y": 0.00,
		"motion": {"wave_amp": 0.030, "wave_freq": 5.8, "dash_shift": 0.096, "turn_shift": 0.050, "dive_shift": 0.020, "jitter": 0.006, "depth_bias": -0.020},
		"action_profile": {"dash": 0.64, "dive": 0.08, "turn": 0.16, "rest": 0.12},
		"action_messages": {"dash": "カツオが表層を猛スピードで走った！", "dive": "カツオが少し沈む！", "turn": "カツオが高速で反転した！", "rest": "カツオの速度が落ちた。巻き時だ！"},
	},
	"shiira":
	{
		"id": "shiira",
		"name": "シイラ",
		"rarity": "レア",
		"min_level": 7,
		"boss": false,
		"weight": 2.5,
		"size_min": 70.0,
		"size_max": 125.0,
		"sell_price": 1380,
		"food_exp": 148,
		"stamina": 146.0,
		"power": 1.25,
		"speed": 1.45,
		"start_distance": 45.0,
		"start_depth": 6.0,
		"color": "#a6bd27",
		"habitat": "外海表層・流れ藻周り",
		"behavior": "水面近くを派手に跳ねるように走る。",
		"fish_no": "No.025",
		"preferred_bait": "小魚",
		"visual_scale": 1.20,
		"line_anchor_x": 0.440,
		"line_anchor_y": 0.00,
		"motion": {"wave_amp": 0.034, "wave_freq": 4.9, "dash_shift": 0.086, "turn_shift": 0.065, "dive_shift": 0.012, "jitter": 0.006, "depth_bias": -0.060},
		"action_profile": {"dash": 0.48, "dive": 0.06, "turn": 0.34, "rest": 0.12},
		"action_messages": {"dash": "シイラが水面近くを派手に走る！", "dive": "シイラが一瞬沈む！", "turn": "シイラが大きく跳ねるように反転した！", "rest": "シイラの勢いが落ちた。巻き上げよう！"},
	},
	"kue":
	{
		"id": "kue",
		"name": "クエ",
		"rarity": "レア",
		"min_level": 8,
		"boss": false,
		"weight": 2.0,
		"size_min": 65.0,
		"size_max": 120.0,
		"sell_price": 1650,
		"food_exp": 165,
		"stamina": 176.0,
		"power": 1.48,
		"speed": 0.62,
		"start_distance": 36.0,
		"start_depth": 20.0,
		"color": "#6b5b43",
		"habitat": "深い岩礁・大岩の穴",
		"behavior": "圧倒的な重さで底へ潜り続ける。",
		"fish_no": "No.026",
		"preferred_bait": "小魚",
		"visual_scale": 1.18,
		"line_anchor_x": 0.405,
		"line_anchor_y": 0.04,
		"motion": {"wave_amp": 0.007, "wave_freq": 1.4, "dash_shift": 0.034, "turn_shift": 0.020, "dive_shift": 0.085, "jitter": 0.001, "depth_bias": 0.090},
		"action_profile": {"dash": 0.18, "dive": 0.58, "turn": 0.06, "rest": 0.18},
		"action_messages": {"dash": "クエが大岩へ突っ込む！", "dive": "クエが底へ沈む！ 糸を出して耐えよう！", "turn": "クエが重く体を返した。", "rest": "クエの重みが少し抜けた。巻き上げよう！"},
	},
	"hiramasa":
	{
		"id": "hiramasa",
		"name": "ヒラマサ",
		"rarity": "レア",
		"min_level": 8,
		"boss": false,
		"weight": 1.8,
		"size_min": 70.0,
		"size_max": 125.0,
		"sell_price": 1720,
		"food_exp": 170,
		"stamina": 168.0,
		"power": 1.42,
		"speed": 1.42,
		"start_distance": 46.0,
		"start_depth": 15.0,
		"color": "#7a9896",
		"habitat": "外海の岩礁帯・潮目",
		"behavior": "鋭い突進で根へ向かう上位青物。",
		"fish_no": "No.027",
		"preferred_bait": "小魚",
		"visual_scale": 1.18,
		"line_anchor_x": 0.445,
		"line_anchor_y": 0.01,
		"motion": {"wave_amp": 0.024, "wave_freq": 4.6, "dash_shift": 0.092, "turn_shift": 0.044, "dive_shift": 0.040, "jitter": 0.003, "depth_bias": 0.005},
		"action_profile": {"dash": 0.58, "dive": 0.20, "turn": 0.10, "rest": 0.12},
		"action_messages": {"dash": "ヒラマサが根へ向かって突進する！", "dive": "ヒラマサが深く入る！ ラインを出して耐えよう！", "turn": "ヒラマサが鋭く反転した！", "rest": "ヒラマサの走りが止まった。今が巻き時だ！"},
	},
	"rouninaji":
	{
		"id": "rouninaji",
		"name": "ロウニンアジ",
		"rarity": "レア",
		"min_level": 9,
		"boss": false,
		"weight": 1.4,
		"size_min": 75.0,
		"size_max": 135.0,
		"sell_price": 2100,
		"food_exp": 190,
		"stamina": 186.0,
		"power": 1.55,
		"speed": 1.30,
		"start_distance": 48.0,
		"start_depth": 16.0,
		"color": "#6d7d85",
		"habitat": "南の外洋・リーフエッジ",
		"behavior": "強烈な横走りと反転でラインを削る。",
		"fish_no": "No.028",
		"preferred_bait": "小魚",
		"visual_scale": 1.20,
		"line_anchor_x": 0.415,
		"line_anchor_y": 0.02,
		"motion": {"wave_amp": 0.020, "wave_freq": 3.8, "dash_shift": 0.090, "turn_shift": 0.060, "dive_shift": 0.052, "jitter": 0.002, "depth_bias": 0.025},
		"action_profile": {"dash": 0.50, "dive": 0.24, "turn": 0.16, "rest": 0.10},
		"action_messages": {"dash": "ロウニンアジが外洋へ突っ走る！", "dive": "ロウニンアジがリーフ際へ潜る！", "turn": "ロウニンアジが強烈に反転した！", "rest": "ロウニンアジの走りが一瞬止まった。巻け！"},
	},
	"kajiki":
	{
		"id": "kajiki",
		"name": "カジキ",
		"rarity": "レア",
		"min_level": 10,
		"boss": false,
		"weight": 1.0,
		"size_min": 140.0,
		"size_max": 260.0,
		"sell_price": 2800,
		"food_exp": 220,
		"stamina": 210.0,
		"power": 1.62,
		"speed": 1.48,
		"start_distance": 55.0,
		"start_depth": 18.0,
		"color": "#304b78",
		"habitat": "外洋の深い潮目",
		"behavior": "巨大な体で外洋へ走り、長期戦になる。",
		"fish_no": "No.029",
		"preferred_bait": "大型ルアー",
		"visual_scale": 1.26,
		"line_anchor_x": 0.485,
		"line_anchor_y": -0.01,
		"motion": {"wave_amp": 0.024, "wave_freq": 3.2, "dash_shift": 0.100, "turn_shift": 0.044, "dive_shift": 0.050, "jitter": 0.001, "depth_bias": 0.020},
		"action_profile": {"dash": 0.58, "dive": 0.22, "turn": 0.08, "rest": 0.12},
		"action_messages": {"dash": "カジキが外洋へ走る！ ラインを出して耐えろ！", "dive": "カジキが深い潮目へ潜る！", "turn": "カジキが巨体を返した！", "rest": "カジキの走りが緩んだ。少しでも巻こう！"},
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
		"fish_no": "No.030",
		"preferred_bait": "岩ガニ",
		"visual_scale": 1.18,
		"line_anchor_x": 0.430,
		"line_anchor_y": 0.03,
		"motion": {"wave_amp": 0.016, "wave_freq": 2.2, "dash_shift": 0.060, "turn_shift": 0.045, "dive_shift": 0.070, "jitter": 0.002, "depth_bias": 0.030},
		"action_profile": {"dash": 0.34, "dive": 0.26, "turn": 0.20, "rest": 0.20},
		"action_messages": {"dash": "ぬしが激しく突進した！ 巻くのを止めよう！", "dive": "ぬしが海底へ潜る！ 糸を出して耐えよう！", "turn": "ぬしが急反転！ テンションの変化に注意！", "rest": "ぬしの動きが鈍った。今が巻き時だ！"},
	},
}

const FISHING_SPOT_ORDER: Array[String] = [
	"harbor_pier",
	"shallow_sand",
	"rock_breakwater",
	"outer_tide",
	"south_reef",
	"bluewater_route",
	"deep_ocean",
	"harbor_boulder",
]

const FISHING_SPOTS: Dictionary = {
		"harbor_pier":
		{
			"id": "harbor_pier",
			"name": "港内・堤防",
			"short_name": "港内",
			"unlock_level": 1,
			"required_boat_rank": NO_BOAT_RANK,
			"depth_range": [5.0, 10.0],
		"description": "足場が良く、小魚が集まる入門ポイント。",
		"common_modifier": 0.85,
		"featured_fish": ["aji", "iwashi", "shirogisu", "mejina", "bora"],
		"recommended_baits": ["アミエビ", "イソメ"],
		"boss_spot": false,
		"allowed_fish": ["aji", "mejina", "kasago", "iwashi", "shirogisu", "isaki", "kawahagi", "mebaru", "ainame", "bora"],
		"fish_weight_modifiers": {"aji": 1.7, "iwashi": 1.8, "shirogisu": 1.2, "mejina": 1.1, "bora": 1.5},
	},
		"shallow_sand":
		{
			"id": "shallow_sand",
			"name": "砂浜・かけあがり",
			"short_name": "砂浜",
			"unlock_level": 2,
			"required_boat_rank": NO_BOAT_RANK,
			"depth_range": [7.0, 15.0],
		"description": "砂地を探る。白身魚や底物を狙いやすい。",
		"common_modifier": 0.75,
		"featured_fish": ["shirogisu", "kawahagi", "kochi", "hirame"],
		"recommended_baits": ["イソメ", "小魚"],
		"boss_spot": false,
		"allowed_fish": ["aji", "mejina", "kasago", "iwashi", "shirogisu", "isaki", "kawahagi", "mebaru", "ainame", "bora", "kochi", "hirame"],
		"fish_weight_modifiers": {"shirogisu": 2.0, "kawahagi": 1.8, "kochi": 2.2, "hirame": 1.8},
	},
		"rock_breakwater":
		{
			"id": "rock_breakwater",
			"name": "岩礁・消波ブロック",
			"short_name": "岩礁",
			"unlock_level": 2,
			"required_boat_rank": NO_BOAT_RANK,
			"depth_range": [9.0, 17.0],
		"description": "根周りを攻める。潜る魚が多く、糸を出す判断が重要。",
		"common_modifier": 0.75,
		"featured_fish": ["kasago", "mebaru", "ainame", "ishidai"],
		"recommended_baits": ["イソメ", "貝"],
		"boss_spot": false,
		"allowed_fish": ["aji", "mejina", "kasago", "iwashi", "shirogisu", "isaki", "kawahagi", "mebaru", "ainame", "bora", "ishidai", "akahata", "kue"],
		"fish_weight_modifiers": {"mejina": 1.4, "kasago": 1.7, "mebaru": 2.0, "ainame": 1.8, "ishidai": 2.1, "akahata": 1.2, "kue": 0.8},
	},
		"outer_tide":
		{
			"id": "outer_tide",
			"name": "港外・潮目",
			"short_name": "潮目",
			"unlock_level": 3,
			"required_boat_rank": NO_BOAT_RANK,
			"depth_range": [8.0, 16.0],
		"description": "潮通しのよい外側。横走りする魚の反応が多い。",
		"common_modifier": 0.65,
		"featured_fish": ["saba", "suzuki", "kamasu", "tachiuo"],
		"recommended_baits": ["小魚", "オキアミ"],
		"boss_spot": false,
		"allowed_fish": ["aji", "mejina", "kasago", "iwashi", "shirogisu", "isaki", "kawahagi", "mebaru", "ainame", "bora", "saba", "suzuki", "kamasu", "tachiuo", "kanpachi", "katsuo"],
		"fish_weight_modifiers": {"saba": 2.1, "suzuki": 2.0, "kamasu": 2.4, "tachiuo": 2.0, "kanpachi": 0.8, "katsuo": 0.7},
	},
		"south_reef":
		{
			"id": "south_reef",
			"name": "南の岩礁",
			"short_name": "南岩礁",
			"unlock_level": 5,
			"required_boat_rank": 1,
			"depth_range": [12.0, 21.0],
		"description": "南側の根とサンゴ帯。色鮮やかな岩礁魚と大物の気配がある。",
		"common_modifier": 0.55,
		"featured_fish": ["akahata", "fuefukidai", "aobudai", "kue"],
		"recommended_baits": ["オキアミ", "小魚", "貝"],
		"boss_spot": false,
		"allowed_fish": ["aji", "mejina", "kasago", "iwashi", "shirogisu", "isaki", "kawahagi", "mebaru", "ainame", "bora", "madai", "ishidai", "akahata", "fuefukidai", "aobudai", "kue", "hiramasa"],
		"fish_weight_modifiers": {"madai": 1.4, "ishidai": 1.4, "akahata": 2.2, "fuefukidai": 2.2, "aobudai": 2.2, "kue": 1.8, "hiramasa": 0.8},
	},
		"bluewater_route":
		{
			"id": "bluewater_route",
			"name": "外海・回遊ルート",
			"short_name": "外海",
			"unlock_level": 6,
			"required_boat_rank": 2,
			"depth_range": [10.0, 20.0],
		"description": "外海へ続く潮筋。青物や表層を走る魚を狙う。",
		"common_modifier": 0.50,
		"featured_fish": ["kanpachi", "buri", "katsuo", "shiira", "hiramasa"],
		"recommended_baits": ["小魚", "大型ルアー"],
		"boss_spot": false,
		"allowed_fish": ["aji", "mejina", "kasago", "iwashi", "shirogisu", "isaki", "kawahagi", "mebaru", "ainame", "bora", "saba", "suzuki", "kamasu", "tachiuo", "kanpachi", "buri", "katsuo", "shiira", "hiramasa", "rouninaji"],
		"fish_weight_modifiers": {"saba": 0.9, "suzuki": 0.8, "kamasu": 0.8, "tachiuo": 0.9, "kanpachi": 3.0, "buri": 3.0, "katsuo": 3.0, "shiira": 3.0, "hiramasa": 2.2, "rouninaji": 0.9},
	},
		"deep_ocean":
		{
			"id": "deep_ocean",
			"name": "外洋の深場",
			"short_name": "外洋",
			"unlock_level": 9,
			"required_boat_rank": 3,
			"depth_range": [15.0, 25.0],
		"description": "外洋の深い潮目。終盤の大物を低確率で狙う。",
		"common_modifier": 0.45,
		"featured_fish": ["rouninaji", "kajiki", "kue", "hiramasa"],
		"recommended_baits": ["小魚", "大型ルアー"],
		"boss_spot": false,
		"allowed_fish": ["aji", "mejina", "kasago", "iwashi", "shirogisu", "isaki", "kawahagi", "mebaru", "ainame", "bora", "madai", "tachiuo", "kanpachi", "buri", "kue", "hiramasa", "rouninaji", "kajiki"],
		"fish_weight_modifiers": {"madai": 0.9, "tachiuo": 0.8, "kanpachi": 1.0, "buri": 1.0, "kue": 1.8, "hiramasa": 1.8, "rouninaji": 2.8, "kajiki": 3.5},
	},
		"harbor_boulder":
		{
			"id": "harbor_boulder",
			"name": "港の大岩",
			"short_name": "大岩",
			"unlock_level": BOSS_UNLOCK_LEVEL,
			"required_boat_rank": NO_BOAT_RANK,
			"depth_range": [16.0, 22.0],
		"description": "港口の大岩周辺。港のぬしに挑む専用ポイント。",
		"common_modifier": 0.0,
		"featured_fish": ["boss_kurodai"],
		"recommended_baits": ["岩ガニ"],
		"boss_spot": true,
		"allowed_fish": ["boss_kurodai"],
		"fish_weight_modifiers": {},
	},
}

const DEFAULT_FISHING_ENVIRONMENT_ID := "sunny_calm"

const FISHING_ENVIRONMENTS: Dictionary = {
	"sunny_calm":
	{
		"id": "sunny_calm",
		"weather_id": "sunny",
		"weather_label": "快晴",
		"wind_id": "weak",
		"wind_label": "風 弱",
		"surface_bgm_key": "calm",
		"weight": 0.70,
	},
	"sunny_windy":
	{
		"id": "sunny_windy",
		"weather_id": "sunny",
		"weather_label": "快晴",
		"wind_id": "strong",
		"wind_label": "風 強",
		"surface_bgm_key": "windy",
		"weight": 0.30,
	},
}

const RECIPES: Dictionary = {
	"salt_grill":
	{
		"id": "salt_grill",
		"name": "塩焼き",
		"unlock_level": 1,
		"exp_multiplier": 1.0,
		"allowed_fish": ["aji", "mejina", "kasago", "isaki", "saba", "suzuki", "madai", "hirame", "kawahagi", "iwashi", "shirogisu", "mebaru", "ainame", "bora", "kamasu", "kochi", "tachiuo", "ishidai", "akahata", "fuefukidai", "aobudai", "kanpachi", "buri", "katsuo", "shiira", "kue", "hiramasa", "rouninaji", "kajiki", "boss_kurodai"],
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
		"allowed_fish": ["aji", "mejina", "isaki", "saba", "suzuki", "madai", "hirame", "kawahagi", "iwashi", "shirogisu", "mebaru", "kamasu", "tachiuo", "ishidai", "akahata", "fuefukidai", "aobudai", "kanpachi", "buri", "katsuo", "shiira", "hiramasa", "rouninaji", "kajiki", "boss_kurodai"],
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
		"allowed_fish": ["mejina", "kasago", "isaki", "madai", "hirame", "kawahagi", "mebaru", "ainame", "bora", "kochi", "tachiuo", "ishidai", "akahata", "fuefukidai", "aobudai", "kue", "boss_kurodai"],
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
		"allowed_fish": ["aji", "mejina", "kasago", "isaki", "saba", "suzuki", "madai", "hirame", "kawahagi", "iwashi", "shirogisu", "mebaru", "ainame", "bora", "kamasu", "kochi", "tachiuo", "ishidai", "akahata", "fuefukidai", "aobudai", "kanpachi", "buri", "katsuo", "shiira", "kue", "hiramasa", "rouninaji", "kajiki", "boss_kurodai"],
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
		"allowed_fish": ["aji", "isaki", "saba", "suzuki", "madai", "hirame", "kawahagi", "iwashi", "shirogisu", "mebaru", "ainame", "kamasu", "kochi", "tachiuo", "akahata", "fuefukidai", "kanpachi", "buri", "katsuo", "shiira", "hiramasa"],
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

const BOAT_ORDER: Array[String] = [
	"skiff",
	"offshore_boat",
	"bluewater_boat",
]

const BOATS: Dictionary = {
	"skiff":
	{
		"id": "skiff",
		"name": "小型船・浜風",
		"short_name": "小型船",
		"rank": 1,
		"price": 3600,
		"description": "港から少し離れた南の岩礁へ向かえる小回りの利く船。",
		"access_text": "南の岩礁まで出航可能",
	},
	"offshore_boat":
	{
		"id": "offshore_boat",
		"name": "沖釣り船・潮路",
		"short_name": "沖釣り船",
		"rank": 2,
		"price": 8200,
		"description": "外海の回遊ルートまで出られる安定した釣り船。",
		"access_text": "外海・回遊ルートまで出航可能",
	},
	"bluewater_boat":
	{
		"id": "bluewater_boat",
		"name": "外洋船・群青",
		"short_name": "外洋船",
		"rank": 3,
		"price": 14500,
		"description": "深い潮目と外洋の大物を狙うための本格船。",
		"access_text": "外洋の深場まで出航可能",
	},
}

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func get_fish(fish_id: String) -> Dictionary:
	if not FISH.has(fish_id):
		return {}
	return FISH[fish_id].duplicate(true)


func get_fishing_spot(spot_id: String) -> Dictionary:
	var resolved_id := _resolved_spot_id(spot_id)
	return FISHING_SPOTS[resolved_id].duplicate(true)


func get_fishing_environment(environment_id: String) -> Dictionary:
	if not FISHING_ENVIRONMENTS.has(environment_id):
		environment_id = DEFAULT_FISHING_ENVIRONMENT_ID
	return FISHING_ENVIRONMENTS[environment_id].duplicate(true)


func roll_fishing_environment() -> Dictionary:
	var total_weight := 0.0
	for environment_variant in FISHING_ENVIRONMENTS.values():
		var environment: Dictionary = environment_variant
		total_weight += maxf(0.0, float(environment.get("weight", 1.0)))
	if total_weight <= 0.0:
		return get_fishing_environment(DEFAULT_FISHING_ENVIRONMENT_ID)
	var target := _rng.randf_range(0.0, total_weight)
	var current := 0.0
	for environment_id in FISHING_ENVIRONMENTS.keys():
		var environment: Dictionary = FISHING_ENVIRONMENTS[environment_id]
		current += maxf(0.0, float(environment.get("weight", 1.0)))
		if target <= current:
			return environment.duplicate(true)
	return get_fishing_environment(DEFAULT_FISHING_ENVIRONMENT_ID)


func get_recipe(recipe_id: String) -> Dictionary:
	if not RECIPES.has(recipe_id):
		return {}
	return RECIPES[recipe_id].duplicate(true)


func get_rod(rod_id: String) -> Dictionary:
	if not RODS.has(rod_id):
		return {}
	return RODS[rod_id].duplicate(true)


func get_boat(boat_id: String) -> Dictionary:
	if not BOATS.has(boat_id):
		return {}
	return BOATS[boat_id].duplicate(true)


func get_all_fish_ids() -> Array[String]:
	var ids: Array[String] = []
	for fish_id in FISH.keys():
		ids.append(String(fish_id))
	return ids


func get_all_fishing_spot_ids() -> Array[String]:
	var ids: Array[String] = []
	for spot_id in FISHING_SPOT_ORDER:
		ids.append(spot_id)
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
	for rod_id in RODS.keys():
		ids.append(String(rod_id))
	return ids


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


func encounter_weights(player_level: int, spot_id: String = DEFAULT_FISHING_SPOT_ID) -> Dictionary:
	var resolved_id := _normal_spot_id_for_roll(spot_id, player_level)
	var spot: Dictionary = FISHING_SPOTS[resolved_id]
	var weights: Dictionary = {}
	var allowed_fish: Array = spot.get("allowed_fish", [])
	var modifiers: Dictionary = spot.get("fish_weight_modifiers", {})
	var common_modifier := float(spot.get("common_modifier", 1.0))
	for fish_id_variant in FISH.keys():
		var fish_id := String(fish_id_variant)
		var fish: Dictionary = FISH[fish_id]
		if bool(fish.get("boss", false)):
			continue
		if int(fish.get("min_level", 1)) > player_level:
			continue
		if not allowed_fish.has(fish_id):
			continue
		var modifier := common_modifier
		if modifiers.has(fish_id):
			modifier = float(modifiers[fish_id])
		var weight := float(fish.get("weight", 0.0)) * maxf(0.0, modifier)
		if weight <= 0.0:
			continue
		weights[fish_id] = weight
	return weights


func roll_normal_fish(player_level: int, spot_id: String = DEFAULT_FISHING_SPOT_ID) -> Dictionary:
	var weights := encounter_weights(player_level, spot_id)
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
	return snappedf(_rng.randf_range(float(fish["size_min"]), float(fish["size_max"])), 0.1)


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
