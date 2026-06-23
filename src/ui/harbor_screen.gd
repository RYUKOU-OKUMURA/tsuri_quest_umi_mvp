extends "res://src/ui/screen_base.gd"

var _status_label: Label
var _buff_label: Label


func _build_screen() -> void:
	add_background(Color("#0b2840"))
	var root := make_root_margin(18)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	(
		layout
		. add_child(
			make_header(
				"南の島・港",
				(
					"Lv.%d　所持金 %d G　装備：%s"
					% [
						PlayerProgress.level,
						PlayerProgress.money,
						String(GameData.get_rod(PlayerProgress.equipped_rod_id).get("name", "入門竿")),
					]
				)
			)
		)
	)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	layout.add_child(body)

	var harbor_panel := make_panel(true)
	harbor_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	harbor_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	harbor_panel.size_flags_stretch_ratio = 1.35
	body.add_child(harbor_panel)
	var harbor_box := VBoxContainer.new()
	harbor_box.alignment = BoxContainer.ALIGNMENT_CENTER
	harbor_box.add_theme_constant_override("separation", 18)
	harbor_panel.add_child(harbor_box)

	var scene_title := make_label("潮風が吹く、小さな漁港", 34, Color("#ffe3a2"))
	scene_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	harbor_box.add_child(scene_title)
	var scene_text := make_label(
		"沖では魚影が濃くなっている。\n釣った魚は市場で売るか、調理場で食べて成長できる。\n準備ができたら海へ出よう。", 21, Color("#dceef7")
	)
	scene_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	harbor_box.add_child(scene_text)

	var loop_panel := make_panel()
	loop_panel.custom_minimum_size = Vector2(620, 110)
	harbor_box.add_child(loop_panel)
	var loop_label := make_label("基本ループ：　釣る　→　売る／料理する　→　装備・レベル強化　→　ぬしに挑む", 19, Color("#25374b"))
	loop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loop_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loop_panel.add_child(loop_label)

	_buff_label = make_label("", 18, Color("#ffdfa0"))
	_buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	harbor_box.add_child(_buff_label)

	var menu_panel := make_panel()
	menu_panel.custom_minimum_size = Vector2(390, 0)
	menu_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(menu_panel)
	var menu_box := VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 11)
	menu_panel.add_child(menu_box)
	var menu_title := make_label("港の施設", 28, Color("#22354a"))
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_box.add_child(menu_title)
	menu_box.add_child(make_button("釣り場へ向かう", func() -> void: navigate("fishing"), 330))
	menu_box.add_child(make_button("調理場", func() -> void: navigate("cooking"), 330))
	menu_box.add_child(make_button("魚市場", func() -> void: navigate("market"), 330))
	menu_box.add_child(make_button("釣具店", func() -> void: navigate("shop"), 330))
	menu_box.add_child(make_button("ステータス・図鑑", func() -> void: navigate("status"), 330))
	menu_box.add_child(make_button("タイトルへ戻る", _return_to_title, 330))

	var footer := make_panel(true)
	footer.custom_minimum_size = Vector2(0, 72)
	layout.add_child(footer)
	_status_label = make_label("", 18, Color("#eaf6ff"))
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_status_label)
	_refresh_labels()


func _refresh_labels() -> void:
	var fish_total := 0
	for count in PlayerProgress.inventory.values():
		fish_total += int(count)
	var next_text := (
		"MAX"
		if PlayerProgress.level >= GameData.MAX_LEVEL
		else "%d / %d EXP" % [PlayerProgress.exp, PlayerProgress.exp_to_next_level()]
	)
	_status_label.text = (
		"クーラーボックス：%d匹　｜　食経験値：%s　｜　プレイ時間：%s"
		% [
			fish_total,
			next_text,
			format_play_time(PlayerProgress.play_seconds),
		]
	)
	if PlayerProgress.pending_buff.is_empty():
		_buff_label.text = "食事効果：なし（調理場で料理を食べると、次の釣行が有利になる）"
	else:
		_buff_label.text = (
			"次の釣行の食事効果：%s　—　%s"
			% [
				String(PlayerProgress.pending_buff.get("name", "料理")),
				String(PlayerProgress.pending_buff.get("text", "")),
			]
		)


func _return_to_title() -> void:
	PlayerProgress.save_game()
	navigate("title")
