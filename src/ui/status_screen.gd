extends "res://src/ui/screen_base.gd"

var _message_label: Label


func _build_screen() -> void:
	add_background(Color("#10243a"))
	var root := make_root_margin(16)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	root.add_child(layout)

	layout.add_child(make_header("ステータス・図鑑", "成長状況、所持品、釣果を確認"))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	layout.add_child(body)

	var stats_panel := make_panel()
	stats_panel.custom_minimum_size = Vector2(350, 0)
	stats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(stats_panel)
	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 10)
	stats_panel.add_child(stats_box)
	var stats_title := make_label("プレイヤー", 27)
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_box.add_child(stats_title)
	var stats := PlayerProgress.get_base_stats()
	var exp_text := (
		"MAX"
		if PlayerProgress.level >= GameData.MAX_LEVEL
		else "%d / %d" % [PlayerProgress.exp, PlayerProgress.exp_to_next_level()]
	)
	var stats_label := make_label(
		(
			"Lv.%d\n食経験値：%s\n所持金：%d G\n\n最大体力：%d\n巻力：%.1f\n技量：%d\n集中力：%d\n安全域：%d〜%d%%\n\n装備：%s"
			% [
				PlayerProgress.level,
				exp_text,
				PlayerProgress.money,
				int(round(float(stats["max_energy"]))),
				float(stats["reel_power"]),
				int(stats["technique"]),
				int(stats["focus"]),
				int(round(float(stats["safe_min"]) * 100.0)),
				int(round(float(stats["safe_max"]) * 100.0)),
				String(stats["rod_name"]),
			]
		),
		20
	)
	stats_box.add_child(stats_label)
	var buff_text := "なし"
	if not PlayerProgress.pending_buff.is_empty():
		buff_text = (
			"%s\n%s"
			% [
				String(PlayerProgress.pending_buff.get("name", "料理")),
				String(PlayerProgress.pending_buff.get("text", ""))
			]
		)
	var buff_label := make_label("次の釣行の食事効果：\n%s" % buff_text, 18)
	stats_box.add_child(buff_label)

	var book_panel := make_panel()
	book_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	book_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(book_panel)
	var book_box := VBoxContainer.new()
	book_box.add_theme_constant_override("separation", 8)
	book_panel.add_child(book_box)
	var book_title := make_label("魚図鑑", 27)
	book_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	book_box.add_child(book_title)
	var book_scroll := ScrollContainer.new()
	book_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	book_box.add_child(book_scroll)
	var book_label := make_label(_build_fishbook_text(), 18)
	book_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	book_scroll.add_child(book_label)

	var collection_panel := make_panel()
	collection_panel.custom_minimum_size = Vector2(350, 0)
	collection_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(collection_panel)
	var collection_box := VBoxContainer.new()
	collection_box.add_theme_constant_override("separation", 8)
	collection_panel.add_child(collection_box)
	var collection_title := make_label("所持品・料理記録", 27)
	collection_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	collection_box.add_child(collection_title)
	var collection_scroll := ScrollContainer.new()
	collection_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	collection_box.add_child(collection_scroll)
	var collection_label := make_label(_build_collection_text(), 18)
	collection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_scroll.add_child(collection_label)

	var footer := make_panel(true)
	footer.custom_minimum_size = Vector2(0, 78)
	layout.add_child(footer)
	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 12)
	footer.add_child(footer_row)
	_message_label = make_label("進行状況は画面切り替え時にも自動保存されます。", 18, Color("#eaf6ff"))
	_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer_row.add_child(_message_label)
	footer_row.add_child(make_button("手動セーブ", _manual_save, 190))
	footer_row.add_child(make_button("港へ戻る", func() -> void: navigate("harbor"), 190))


func _build_fishbook_text() -> String:
	var lines: Array[String] = []
	var discovered := 0
	for fish_id in GameData.get_all_fish_ids():
		var fish := GameData.get_fish(fish_id)
		var count := int(PlayerProgress.caught_counts.get(fish_id, 0))
		if count <= 0:
			lines.append("？？？　未発見\n")
			continue
		discovered += 1
		(
			lines
			. append(
				(
					"%s　[%s]\n  釣果：%d匹　最大：%.1f cm\n  %s\n"
					% [
						String(fish["name"]),
						String(fish["rarity"]),
						count,
						float(PlayerProgress.best_sizes.get(fish_id, 0.0)),
						String(fish["habitat"]),
					]
				)
			)
		)
	lines.push_front("発見数：%d / %d\n\n" % [discovered, GameData.get_all_fish_ids().size()])
	return "".join(PackedStringArray(lines))


func _build_collection_text() -> String:
	var inventory_lines: Array[String] = ["【クーラーボックス】"]
	var has_fish := false
	for fish_id in GameData.get_all_fish_ids():
		var count := PlayerProgress.fish_count(fish_id)
		if count <= 0:
			continue
		has_fish = true
		inventory_lines.append("%s × %d" % [String(GameData.get_fish(fish_id)["name"]), count])
	if not has_fish:
		inventory_lines.append("魚はいません")

	inventory_lines.append("\n【所持している竿】")
	for rod_id in PlayerProgress.owned_rods:
		var marker := "（装備中）" if rod_id == PlayerProgress.equipped_rod_id else ""
		inventory_lines.append("%s%s" % [String(GameData.get_rod(rod_id)["name"]), marker])

	inventory_lines.append("\n【食べた料理】")
	if PlayerProgress.eaten_recipes.is_empty():
		inventory_lines.append("まだありません")
	else:
		for dish_key_variant in PlayerProgress.eaten_recipes.keys():
			var dish_key := String(dish_key_variant)
			var parts := dish_key.split(":")
			if parts.size() != 2:
				continue
			var fish := GameData.get_fish(parts[0])
			var recipe := GameData.get_recipe(parts[1])
			if fish.is_empty() or recipe.is_empty():
				continue
			(
				inventory_lines
				. append(
					(
						"%sの%s × %d"
						% [
							String(fish["name"]),
							String(recipe["name"]),
							int(PlayerProgress.eaten_recipes[dish_key]),
						]
					)
				)
			)
	return "\n".join(PackedStringArray(inventory_lines))


func _manual_save() -> void:
	PlayerProgress.save_game()
	_message_label.text = "セーブしました。保存先：user://tsuri_quest_save.json"
