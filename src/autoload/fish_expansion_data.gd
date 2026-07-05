extends RefCounted

const ROWS: Array[Dictionary] = [
	# No.031-038: 港内・堤防
	{"id": "mahaze", "name": "マハゼ", "rarity": "コモン", "min_level": 1, "weight": 18.0, "size_min": 8.0, "size_max": 24.0, "sell_price": 110, "food_exp": 18, "stamina": 36.0, "power": 0.54, "speed": 0.82, "start_distance": 17.0, "start_depth": 6.0, "color": "#b58a54", "habitat": "港内の砂泥底", "behavior": "底で小さく跳ねる。短い潜り込みに注意。", "fish_no": "No.031", "preferred_bait": "イソメ", "visual_scale": 0.72, "line_anchor_x": 0.430, "line_anchor_y": 0.05, "style": "bottom"},
	{"id": "umitanago", "name": "ウミタナゴ", "rarity": "コモン", "min_level": 1, "weight": 16.0, "size_min": 12.0, "size_max": 28.0, "sell_price": 130, "food_exp": 21, "stamina": 42.0, "power": 0.62, "speed": 0.92, "start_distance": 19.0, "start_depth": 7.0, "color": "#87a0a4", "habitat": "港内の海藻まわり", "behavior": "岸壁沿いで細かく向きを変える。", "fish_no": "No.032", "preferred_bait": "オキアミ", "visual_scale": 0.76, "line_anchor_x": 0.420, "line_anchor_y": 0.04, "style": "balanced"},
	{"id": "sappa", "name": "サッパ", "rarity": "コモン", "min_level": 1, "weight": 20.0, "size_min": 10.0, "size_max": 18.0, "sell_price": 85, "food_exp": 14, "stamina": 30.0, "power": 0.42, "speed": 1.22, "start_distance": 16.0, "start_depth": 5.0, "color": "#b8c6cc", "habitat": "港内の小魚の群れ", "behavior": "群れで浅場を走る。軽い引きだが速い。", "fish_no": "No.033", "preferred_bait": "アミエビ", "visual_scale": 0.64, "line_anchor_x": 0.465, "line_anchor_y": 0.02, "style": "small_fast"},
	{"id": "konoshiro", "name": "コノシロ", "rarity": "コモン", "min_level": 2, "weight": 11.0, "size_min": 12.0, "size_max": 32.0, "sell_price": 180, "food_exp": 30, "stamina": 58.0, "power": 0.76, "speed": 1.08, "start_distance": 24.0, "start_depth": 6.0, "color": "#a9b6b7", "habitat": "港内から港外の回遊筋", "behavior": "横へ走りながら群れへ戻ろうとする。", "fish_no": "No.034", "preferred_bait": "アミエビ", "visual_scale": 0.86, "line_anchor_x": 0.455, "line_anchor_y": 0.02, "style": "small_fast"},
	{"id": "sayori", "name": "サヨリ", "rarity": "アンコモン", "min_level": 2, "weight": 9.0, "size_min": 18.0, "size_max": 40.0, "sell_price": 260, "food_exp": 38, "stamina": 56.0, "power": 0.70, "speed": 1.36, "start_distance": 26.0, "start_depth": 4.0, "color": "#c5d8dc", "habitat": "港内の表層", "behavior": "表層を細く走る。急な反転が多い。", "fish_no": "No.035", "preferred_bait": "アミエビ", "visual_scale": 0.82, "line_anchor_x": 0.500, "line_anchor_y": 0.00, "style": "slender"},
	{"id": "maanago", "name": "マアナゴ", "rarity": "アンコモン", "min_level": 3, "weight": 7.0, "size_min": 35.0, "size_max": 70.0, "sell_price": 420, "food_exp": 64, "stamina": 86.0, "power": 1.04, "speed": 0.58, "start_distance": 25.0, "start_depth": 11.0, "color": "#6f5a3d", "habitat": "港内の夜の底まわり", "behavior": "底を這うように粘り、巻き上げを重くする。", "fish_no": "No.036", "preferred_bait": "イソメ", "visual_scale": 1.02, "line_anchor_x": 0.430, "line_anchor_y": 0.03, "style": "bottom"},
	{"id": "kyusen", "name": "キュウセン", "rarity": "コモン", "min_level": 2, "weight": 13.0, "size_min": 12.0, "size_max": 30.0, "sell_price": 170, "food_exp": 26, "stamina": 48.0, "power": 0.66, "speed": 0.98, "start_distance": 20.0, "start_depth": 8.0, "color": "#84b36a", "habitat": "港内の岩混じりの砂地", "behavior": "小刻みに潜って砂地へ逃げ込む。", "fish_no": "No.037", "preferred_bait": "イソメ", "visual_scale": 0.74, "line_anchor_x": 0.430, "line_anchor_y": 0.04, "style": "bottom"},
	{"id": "nenbutsudai", "name": "ネンブツダイ", "rarity": "コモン", "min_level": 2, "weight": 14.0, "size_min": 8.0, "size_max": 14.0, "sell_price": 95, "food_exp": 16, "stamina": 34.0, "power": 0.48, "speed": 1.05, "start_distance": 17.0, "start_depth": 7.0, "color": "#c76f58", "habitat": "港内の岸壁や小岩の陰", "behavior": "小さな反転を繰り返す。テンションを抜きすぎない。", "fish_no": "No.038", "preferred_bait": "オキアミ", "visual_scale": 0.62, "line_anchor_x": 0.415, "line_anchor_y": 0.04, "style": "small_fast"},
	# No.039-044: 砂浜・かけあがり
	{"id": "makogarei", "name": "マコガレイ", "rarity": "アンコモン", "min_level": 3, "weight": 8.0, "size_min": 18.0, "size_max": 50.0, "sell_price": 430, "food_exp": 60, "stamina": 78.0, "power": 0.94, "speed": 0.58, "start_distance": 24.0, "start_depth": 13.0, "color": "#8a714e", "habitat": "砂浜のかけあがり", "behavior": "砂に張りつくように抵抗する。", "fish_no": "No.039", "preferred_bait": "イソメ", "visual_scale": 0.94, "line_anchor_x": 0.385, "line_anchor_y": 0.06, "style": "flat"},
	{"id": "ishigarei", "name": "イシガレイ", "rarity": "アンコモン", "min_level": 3, "weight": 7.0, "size_min": 20.0, "size_max": 60.0, "sell_price": 520, "food_exp": 70, "stamina": 90.0, "power": 1.02, "speed": 0.56, "start_distance": 26.0, "start_depth": 14.0, "color": "#7d755d", "habitat": "砂浜の深めの砂地", "behavior": "底へ重く潜り、ゆっくり粘る。", "fish_no": "No.040", "preferred_bait": "イソメ", "visual_scale": 1.00, "line_anchor_x": 0.385, "line_anchor_y": 0.06, "style": "flat"},
	{"id": "shitabirame", "name": "シタビラメ", "rarity": "コモン", "min_level": 2, "weight": 10.0, "size_min": 15.0, "size_max": 40.0, "sell_price": 240, "food_exp": 36, "stamina": 52.0, "power": 0.66, "speed": 0.62, "start_distance": 20.0, "start_depth": 11.0, "color": "#a48662", "habitat": "浅い砂地の底", "behavior": "底を滑るように逃げる。短く巻こう。", "fish_no": "No.041", "preferred_bait": "イソメ", "visual_scale": 0.78, "line_anchor_x": 0.395, "line_anchor_y": 0.06, "style": "flat"},
	{"id": "houbou", "name": "ホウボウ", "rarity": "アンコモン", "min_level": 4, "weight": 6.0, "size_min": 20.0, "size_max": 50.0, "sell_price": 620, "food_exp": 78, "stamina": 92.0, "power": 1.02, "speed": 0.86, "start_distance": 28.0, "start_depth": 14.0, "color": "#c75b42", "habitat": "砂浜沖の底", "behavior": "底から浮いて強く首を振る。", "fish_no": "No.042", "preferred_bait": "小魚", "visual_scale": 0.94, "line_anchor_x": 0.410, "line_anchor_y": 0.03, "style": "bottom"},
	{"id": "kanagashira", "name": "カナガシラ", "rarity": "コモン", "min_level": 3, "weight": 8.0, "size_min": 15.0, "size_max": 30.0, "sell_price": 330, "food_exp": 48, "stamina": 62.0, "power": 0.82, "speed": 0.76, "start_distance": 22.0, "start_depth": 13.0, "color": "#c16442", "habitat": "砂地と小岩の境目", "behavior": "底で小さく暴れ、たまに強く潜る。", "fish_no": "No.043", "preferred_bait": "イソメ", "visual_scale": 0.76, "line_anchor_x": 0.410, "line_anchor_y": 0.04, "style": "bottom"},
	{"id": "megochi", "name": "メゴチ", "rarity": "コモン", "min_level": 2, "weight": 12.0, "size_min": 10.0, "size_max": 22.0, "sell_price": 140, "food_exp": 22, "stamina": 38.0, "power": 0.52, "speed": 0.70, "start_distance": 18.0, "start_depth": 9.0, "color": "#8d7655", "habitat": "砂浜の浅い底", "behavior": "底を這ってじわじわ抵抗する。", "fish_no": "No.044", "preferred_bait": "イソメ", "visual_scale": 0.66, "line_anchor_x": 0.405, "line_anchor_y": 0.05, "style": "bottom"},
	# No.045-051: 岩礁・消波ブロック
	{"id": "ishigakidai", "name": "イシガキダイ", "rarity": "レア", "min_level": 5, "weight": 3.4, "size_min": 20.0, "size_max": 70.0, "sell_price": 980, "food_exp": 112, "stamina": 132.0, "power": 1.36, "speed": 0.82, "start_distance": 33.0, "start_depth": 17.0, "color": "#5e5b4c", "habitat": "岩礁の荒い根まわり", "behavior": "根へ潜る力が強く、巻きすぎると危険。", "fish_no": "No.045", "preferred_bait": "貝", "visual_scale": 1.04, "line_anchor_x": 0.415, "line_anchor_y": 0.04, "style": "rock_power"},
	{"id": "kurosoi", "name": "クロソイ", "rarity": "アンコモン", "min_level": 3, "weight": 8.0, "size_min": 15.0, "size_max": 55.0, "sell_price": 460, "food_exp": 62, "stamina": 82.0, "power": 1.00, "speed": 0.68, "start_distance": 24.0, "start_depth": 13.0, "color": "#424037", "habitat": "消波ブロックの暗い穴", "behavior": "穴へ潜り込もうとする。早めに浮かせたい。", "fish_no": "No.046", "preferred_bait": "イソメ", "visual_scale": 0.86, "line_anchor_x": 0.398, "line_anchor_y": 0.04, "style": "rock_power"},
	{"id": "murasoi", "name": "ムラソイ", "rarity": "コモン", "min_level": 2, "weight": 10.0, "size_min": 12.0, "size_max": 30.0, "sell_price": 260, "food_exp": 38, "stamina": 56.0, "power": 0.80, "speed": 0.66, "start_distance": 20.0, "start_depth": 11.0, "color": "#5d4a37", "habitat": "岩礁の浅い穴", "behavior": "短く潜って岩陰へ戻ろうとする。", "fish_no": "No.047", "preferred_bait": "イソメ", "visual_scale": 0.74, "line_anchor_x": 0.400, "line_anchor_y": 0.04, "style": "rock_power"},
	{"id": "takenokomebaru", "name": "タケノコメバル", "rarity": "アンコモン", "min_level": 4, "weight": 6.5, "size_min": 15.0, "size_max": 45.0, "sell_price": 560, "food_exp": 74, "stamina": 90.0, "power": 1.06, "speed": 0.72, "start_distance": 25.0, "start_depth": 12.0, "color": "#7b5b34", "habitat": "岩礁の海藻と根の間", "behavior": "根へ入る前に強く止める必要がある。", "fish_no": "No.048", "preferred_bait": "小魚", "visual_scale": 0.90, "line_anchor_x": 0.405, "line_anchor_y": 0.04, "style": "rock_power"},
	{"id": "oomonhata", "name": "オオモンハタ", "rarity": "レア", "min_level": 5, "weight": 3.6, "size_min": 20.0, "size_max": 60.0, "sell_price": 1080, "food_exp": 122, "stamina": 136.0, "power": 1.34, "speed": 0.88, "start_distance": 34.0, "start_depth": 17.0, "color": "#9a6b3f", "habitat": "岩礁の深い根", "behavior": "強い首振りと潜りで主導権を奪う。", "fish_no": "No.049", "preferred_bait": "小魚", "visual_scale": 1.06, "line_anchor_x": 0.405, "line_anchor_y": 0.03, "style": "rock_power"},
	{"id": "onikasago", "name": "オニカサゴ", "rarity": "レア", "min_level": 6, "weight": 2.8, "size_min": 18.0, "size_max": 50.0, "sell_price": 1180, "food_exp": 132, "stamina": 128.0, "power": 1.40, "speed": 0.58, "start_distance": 30.0, "start_depth": 19.0, "color": "#b34a38", "habitat": "深めの岩礁底", "behavior": "底に張りつき、重い抵抗で粘る。", "fish_no": "No.050", "preferred_bait": "小魚", "visual_scale": 0.96, "line_anchor_x": 0.398, "line_anchor_y": 0.05, "style": "rock_power"},
	{"id": "kobudai", "name": "コブダイ", "rarity": "レア", "min_level": 6, "weight": 2.4, "size_min": 30.0, "size_max": 95.0, "sell_price": 1450, "food_exp": 150, "stamina": 164.0, "power": 1.52, "speed": 0.78, "start_distance": 36.0, "start_depth": 18.0, "color": "#6b6a5e", "habitat": "大きな岩礁の根まわり", "behavior": "重量級の突進で根へ戻ろうとする。", "fish_no": "No.051", "preferred_bait": "貝", "visual_scale": 1.18, "line_anchor_x": 0.410, "line_anchor_y": 0.04, "style": "big_power"},
	# No.052-055: 港外・潮目
	{"id": "sawara", "name": "サワラ", "rarity": "レア", "min_level": 5, "weight": 4.0, "size_min": 40.0, "size_max": 110.0, "sell_price": 1250, "food_exp": 138, "stamina": 132.0, "power": 1.24, "speed": 1.55, "start_distance": 42.0, "start_depth": 10.0, "color": "#8fa7aa", "habitat": "港外の潮目", "behavior": "鋭く横へ走る。巻くタイミングが重要。", "fish_no": "No.052", "preferred_bait": "大型ルアー", "visual_scale": 1.08, "line_anchor_x": 0.490, "line_anchor_y": 0.01, "style": "pelagic_fast"},
	{"id": "datsu", "name": "ダツ", "rarity": "アンコモン", "min_level": 4, "weight": 5.5, "size_min": 45.0, "size_max": 90.0, "sell_price": 640, "food_exp": 82, "stamina": 96.0, "power": 0.96, "speed": 1.62, "start_distance": 36.0, "start_depth": 5.0, "color": "#9bb6b5", "habitat": "港外の表層", "behavior": "表層を一直線に走り、急に反転する。", "fish_no": "No.053", "preferred_bait": "小魚", "visual_scale": 1.00, "line_anchor_x": 0.520, "line_anchor_y": 0.00, "style": "slender"},
	{"id": "hirasouda", "name": "ヒラソウダ", "rarity": "アンコモン", "min_level": 5, "weight": 4.8, "size_min": 25.0, "size_max": 58.0, "sell_price": 780, "food_exp": 94, "stamina": 108.0, "power": 1.10, "speed": 1.52, "start_distance": 38.0, "start_depth": 9.0, "color": "#445d78", "habitat": "港外の速い潮", "behavior": "速度で主導権を取る回遊魚。", "fish_no": "No.054", "preferred_bait": "大型ルアー", "visual_scale": 0.96, "line_anchor_x": 0.480, "line_anchor_y": 0.01, "style": "pelagic_fast"},
	{"id": "suma", "name": "スマ", "rarity": "レア", "min_level": 6, "weight": 3.2, "size_min": 30.0, "size_max": 75.0, "sell_price": 1120, "food_exp": 126, "stamina": 126.0, "power": 1.22, "speed": 1.48, "start_distance": 41.0, "start_depth": 10.0, "color": "#3e536e", "habitat": "港外の潮目の外側", "behavior": "強い横走りを連発する。体力管理が要る。", "fish_no": "No.055", "preferred_bait": "大型ルアー", "visual_scale": 1.00, "line_anchor_x": 0.480, "line_anchor_y": 0.01, "style": "pelagic_fast"},
	# No.056-059: 南の岩礁
	{"id": "ojisan", "name": "オジサン", "rarity": "コモン", "min_level": 5, "weight": 7.0, "size_min": 15.0, "size_max": 35.0, "sell_price": 360, "food_exp": 52, "stamina": 70.0, "power": 0.82, "speed": 0.88, "start_distance": 24.0, "start_depth": 12.0, "color": "#b06b48", "habitat": "南の岩礁の砂混じりの底", "behavior": "底で首を振り、短く潜る。", "fish_no": "No.056", "preferred_bait": "オキアミ", "visual_scale": 0.78, "line_anchor_x": 0.415, "line_anchor_y": 0.04, "style": "bottom"},
	{"id": "takabe", "name": "タカベ", "rarity": "コモン", "min_level": 5, "weight": 8.0, "size_min": 12.0, "size_max": 28.0, "sell_price": 300, "food_exp": 44, "stamina": 60.0, "power": 0.72, "speed": 1.24, "start_distance": 26.0, "start_depth": 8.0, "color": "#80a36a", "habitat": "南の岩礁の中層", "behavior": "群れから離れないよう細かく走る。", "fish_no": "No.057", "preferred_bait": "アミエビ", "visual_scale": 0.72, "line_anchor_x": 0.455, "line_anchor_y": 0.02, "style": "small_fast"},
	{"id": "ira", "name": "イラ", "rarity": "アンコモン", "min_level": 6, "weight": 4.2, "size_min": 25.0, "size_max": 45.0, "sell_price": 760, "food_exp": 92, "stamina": 112.0, "power": 1.12, "speed": 0.86, "start_distance": 32.0, "start_depth": 15.0, "color": "#b88465", "habitat": "南の岩礁の根まわり", "behavior": "根際で反転し、重く潜る。", "fish_no": "No.058", "preferred_bait": "貝", "visual_scale": 0.98, "line_anchor_x": 0.410, "line_anchor_y": 0.04, "style": "rock_power"},
	{"id": "meichidai", "name": "メイチダイ", "rarity": "レア", "min_level": 7, "weight": 2.8, "size_min": 20.0, "size_max": 48.0, "sell_price": 1320, "food_exp": 140, "stamina": 124.0, "power": 1.24, "speed": 0.98, "start_distance": 35.0, "start_depth": 16.0, "color": "#bc7f58", "habitat": "南の岩礁の潮通し", "behavior": "中層で粘り、時々強く根へ走る。", "fish_no": "No.059", "preferred_bait": "オキアミ", "visual_scale": 0.96, "line_anchor_x": 0.420, "line_anchor_y": 0.03, "style": "balanced"},
	# No.060-063: 外海・回遊ルート
	{"id": "shimaaji", "name": "シマアジ", "rarity": "レア", "min_level": 7, "weight": 2.6, "size_min": 25.0, "size_max": 90.0, "sell_price": 1580, "food_exp": 156, "stamina": 142.0, "power": 1.28, "speed": 1.36, "start_distance": 42.0, "start_depth": 12.0, "color": "#899a9f", "habitat": "外海の回遊ルート", "behavior": "力強く横へ走り、反転も鋭い。", "fish_no": "No.060", "preferred_bait": "オキアミ", "visual_scale": 1.04, "line_anchor_x": 0.470, "line_anchor_y": 0.02, "style": "pelagic_fast"},
	{"id": "tsumuburi", "name": "ツムブリ", "rarity": "レア", "min_level": 8, "weight": 2.2, "size_min": 40.0, "size_max": 110.0, "sell_price": 1780, "food_exp": 174, "stamina": 158.0, "power": 1.34, "speed": 1.50, "start_distance": 46.0, "start_depth": 14.0, "color": "#4f8c86", "habitat": "外海の潮筋", "behavior": "長い横走りでラインを引き出す。", "fish_no": "No.061", "preferred_bait": "大型ルアー", "visual_scale": 1.14, "line_anchor_x": 0.485, "line_anchor_y": 0.01, "style": "pelagic_fast"},
	{"id": "gingameaji", "name": "ギンガメアジ", "rarity": "レア", "min_level": 8, "weight": 2.1, "size_min": 30.0, "size_max": 90.0, "sell_price": 1760, "food_exp": 172, "stamina": 160.0, "power": 1.38, "speed": 1.32, "start_distance": 45.0, "start_depth": 14.0, "color": "#6f858e", "habitat": "外海の速い潮", "behavior": "重い突進と反転を繰り返す。", "fish_no": "No.062", "preferred_bait": "小魚", "visual_scale": 1.10, "line_anchor_x": 0.465, "line_anchor_y": 0.02, "style": "big_power"},
	{"id": "kaiwari", "name": "カイワリ", "rarity": "アンコモン", "min_level": 6, "weight": 4.4, "size_min": 15.0, "size_max": 40.0, "sell_price": 680, "food_exp": 86, "stamina": 88.0, "power": 0.94, "speed": 1.24, "start_distance": 30.0, "start_depth": 11.0, "color": "#a7b3b5", "habitat": "外海手前の中層", "behavior": "小型ながら鋭く横へ走る。", "fish_no": "No.063", "preferred_bait": "オキアミ", "visual_scale": 0.84, "line_anchor_x": 0.455, "line_anchor_y": 0.02, "style": "pelagic_fast"},
	# No.064-070: 外洋の深場
	{"id": "kihada", "name": "キハダマグロ", "rarity": "レア", "min_level": 10, "weight": 0.9, "size_min": 60.0, "size_max": 180.0, "sell_price": 3200, "food_exp": 240, "stamina": 230.0, "power": 1.68, "speed": 1.58, "start_distance": 58.0, "start_depth": 18.0, "color": "#3a6d88", "habitat": "外洋の深い潮目", "behavior": "外洋へ一気に走る最終盤の大物。", "fish_no": "No.064", "preferred_bait": "大型ルアー", "visual_scale": 1.28, "line_anchor_x": 0.490, "line_anchor_y": 0.00, "style": "pelagic_fast"},
	{"id": "binnaga", "name": "ビンナガ", "rarity": "レア", "min_level": 9, "weight": 1.2, "size_min": 60.0, "size_max": 135.0, "sell_price": 2600, "food_exp": 210, "stamina": 202.0, "power": 1.52, "speed": 1.42, "start_distance": 52.0, "start_depth": 17.0, "color": "#5a7787", "habitat": "外洋の回遊層", "behavior": "長い胸びれで滑るように走る。", "fish_no": "No.065", "preferred_bait": "大型ルアー", "visual_scale": 1.22, "line_anchor_x": 0.490, "line_anchor_y": 0.00, "style": "pelagic_fast"},
	{"id": "mebachi", "name": "メバチマグロ", "rarity": "レア", "min_level": 10, "weight": 0.8, "size_min": 70.0, "size_max": 190.0, "sell_price": 3400, "food_exp": 250, "stamina": 242.0, "power": 1.72, "speed": 1.42, "start_distance": 60.0, "start_depth": 20.0, "color": "#394f67", "habitat": "外洋の深い回遊層", "behavior": "深場へ潜りながら力で引き続ける。", "fish_no": "No.066", "preferred_bait": "大型ルアー", "visual_scale": 1.30, "line_anchor_x": 0.490, "line_anchor_y": 0.00, "style": "big_power"},
	{"id": "akamutsu", "name": "アカムツ", "rarity": "レア", "min_level": 9, "weight": 1.4, "size_min": 20.0, "size_max": 50.0, "sell_price": 2400, "food_exp": 205, "stamina": 150.0, "power": 1.28, "speed": 0.66, "start_distance": 38.0, "start_depth": 23.0, "color": "#b4413a", "habitat": "外洋の深場の底", "behavior": "深い底で重く粘り、巻き上げを遅らせる。", "fish_no": "No.067", "preferred_bait": "小魚", "visual_scale": 0.92, "line_anchor_x": 0.410, "line_anchor_y": 0.05, "style": "deep"},
	{"id": "kinmedai", "name": "キンメダイ", "rarity": "レア", "min_level": 9, "weight": 1.5, "size_min": 20.0, "size_max": 55.0, "sell_price": 2300, "food_exp": 198, "stamina": 146.0, "power": 1.22, "speed": 0.72, "start_distance": 39.0, "start_depth": 22.0, "color": "#c33f3d", "habitat": "外洋の暗い深場", "behavior": "深場からゆっくり重く抵抗する。", "fish_no": "No.068", "preferred_bait": "小魚", "visual_scale": 0.98, "line_anchor_x": 0.415, "line_anchor_y": 0.04, "style": "deep"},
	{"id": "ara", "name": "アラ", "rarity": "レア", "min_level": 10, "weight": 0.9, "size_min": 40.0, "size_max": 130.0, "sell_price": 3600, "food_exp": 260, "stamina": 238.0, "power": 1.78, "speed": 0.70, "start_distance": 45.0, "start_depth": 24.0, "color": "#7a5f48", "habitat": "外洋の深場の岩礁", "behavior": "巨体で底へ張りつく。強引な巻き上げは危険。", "fish_no": "No.069", "preferred_bait": "小魚", "visual_scale": 1.24, "line_anchor_x": 0.405, "line_anchor_y": 0.05, "style": "big_power"},
	{"id": "medai", "name": "メダイ", "rarity": "アンコモン", "min_level": 8, "weight": 2.2, "size_min": 35.0, "size_max": 90.0, "sell_price": 1500, "food_exp": 160, "stamina": 162.0, "power": 1.30, "speed": 0.92, "start_distance": 40.0, "start_depth": 20.0, "color": "#6f7f83", "habitat": "外洋の中深場", "behavior": "中深場で重く首を振る。", "fish_no": "No.070", "preferred_bait": "小魚", "visual_scale": 1.08, "line_anchor_x": 0.420, "line_anchor_y": 0.04, "style": "deep"},
]


static func all_fish() -> Dictionary:
	var fish_by_id: Dictionary = {}
	for row in ROWS:
		var fish := _build_fish(row)
		fish_by_id[String(fish["id"])] = fish
	return fish_by_id


static func _build_fish(row: Dictionary) -> Dictionary:
	var fish := row.duplicate(true)
	var style := String(fish.get("style", "balanced"))
	fish.erase("style")
	fish["boss"] = false
	fish["motion"] = _motion_for_style(style)
	fish["action_profile"] = _action_profile_for_style(style)
	fish["action_messages"] = _action_messages_for_style(String(fish["name"]), style)
	return fish


static func _motion_for_style(style: String) -> Dictionary:
	match style:
		"small_fast":
			return {"wave_amp": 0.026, "wave_freq": 4.2, "dash_shift": 0.052, "turn_shift": 0.060, "dive_shift": 0.020, "jitter": 0.006, "depth_bias": -0.006}
		"bottom":
			return {"wave_amp": 0.012, "wave_freq": 1.8, "dash_shift": 0.032, "turn_shift": 0.030, "dive_shift": 0.062, "jitter": 0.002, "depth_bias": 0.055}
		"flat":
			return {"wave_amp": 0.008, "wave_freq": 1.5, "dash_shift": 0.026, "turn_shift": 0.024, "dive_shift": 0.070, "jitter": 0.001, "depth_bias": 0.070}
		"rock_power":
			return {"wave_amp": 0.014, "wave_freq": 2.1, "dash_shift": 0.046, "turn_shift": 0.036, "dive_shift": 0.074, "jitter": 0.002, "depth_bias": 0.048}
		"pelagic_fast":
			return {"wave_amp": 0.024, "wave_freq": 3.4, "dash_shift": 0.092, "turn_shift": 0.044, "dive_shift": 0.034, "jitter": 0.002, "depth_bias": -0.004}
		"big_power":
			return {"wave_amp": 0.016, "wave_freq": 2.2, "dash_shift": 0.068, "turn_shift": 0.040, "dive_shift": 0.070, "jitter": 0.001, "depth_bias": 0.036}
		"slender":
			return {"wave_amp": 0.022, "wave_freq": 3.8, "dash_shift": 0.080, "turn_shift": 0.058, "dive_shift": 0.020, "jitter": 0.003, "depth_bias": -0.012}
		"deep":
			return {"wave_amp": 0.010, "wave_freq": 1.6, "dash_shift": 0.038, "turn_shift": 0.026, "dive_shift": 0.086, "jitter": 0.001, "depth_bias": 0.080}
		_:
			return {"wave_amp": 0.018, "wave_freq": 2.6, "dash_shift": 0.044, "turn_shift": 0.042, "dive_shift": 0.040, "jitter": 0.003, "depth_bias": 0.014}


static func _action_profile_for_style(style: String) -> Dictionary:
	match style:
		"small_fast":
			return {"dash": 0.28, "dive": 0.10, "turn": 0.42, "rest": 0.20}
		"bottom":
			return {"dash": 0.24, "dive": 0.40, "turn": 0.14, "rest": 0.22}
		"flat":
			return {"dash": 0.16, "dive": 0.48, "turn": 0.12, "rest": 0.24}
		"rock_power":
			return {"dash": 0.30, "dive": 0.38, "turn": 0.14, "rest": 0.18}
		"pelagic_fast":
			return {"dash": 0.54, "dive": 0.12, "turn": 0.20, "rest": 0.14}
		"big_power":
			return {"dash": 0.40, "dive": 0.30, "turn": 0.12, "rest": 0.18}
		"slender":
			return {"dash": 0.46, "dive": 0.08, "turn": 0.34, "rest": 0.12}
		"deep":
			return {"dash": 0.20, "dive": 0.48, "turn": 0.10, "rest": 0.22}
		_:
			return {"dash": 0.26, "dive": 0.22, "turn": 0.28, "rest": 0.24}


static func _action_messages_for_style(name: String, style: String) -> Dictionary:
	match style:
		"small_fast":
			return {"dash": "%sが群れへ走った！ テンションを保とう！" % name, "dive": "%sが少し潜る！ 焦らず合わせよう。" % name, "turn": "%sが素早く反転した！" % name, "rest": "%sの動きが緩んだ。巻き上げよう！" % name}
		"bottom", "flat", "deep":
			return {"dash": "%sが底を横へ走る！ 竿を立てよう！" % name, "dive": "%sが底へ張りつく！ 糸を出して粘ろう！" % name, "turn": "%sが底で向きを変えた。テンション注意！" % name, "rest": "%sが少し浮いた。巻き上げるチャンス！" % name}
		"rock_power", "big_power":
			return {"dash": "%sが根へ突っ込む！ 無理に巻かず耐えよう！" % name, "dive": "%sが深く潜る！ ラインを出して耐えよう！" % name, "turn": "%sが岩陰で反転した！" % name, "rest": "%sの重い抵抗が緩んだ。今が巻き時だ！" % name}
		"pelagic_fast", "slender":
			return {"dash": "%sが一気に横走りした！ ラインを出そう！" % name, "dive": "%sが潮の下へ入る！ テンションを見よう！" % name, "turn": "%sが鋭く向きを変えた！" % name, "rest": "%sの走りが止まった。素早く巻こう！" % name}
		_:
			return {"dash": "%sが走った！ テンションを見て耐えよう！" % name, "dive": "%sが潜る！ 糸を出して粘ろう！" % name, "turn": "%sが反転した！" % name, "rest": "%sの動きが緩んだ。巻き上げよう！" % name}
