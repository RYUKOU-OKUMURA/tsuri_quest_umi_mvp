extends Node
## サメ釣り手動QA用: スロット2へ Lv30 + 危険海域解放済みのセーブを書き込む。
## 本番 user:// へ書くため、必ず tools/seed_shark_test_save.sh 経由で実行すること。

const TARGET_SLOT := 2


func _ready() -> void:
	if OS.get_environment("TSURI_SEED_SHARK_TEST_SAVE_ALLOW") != "1":
		push_error(
			"seed_shark_test_save は slot %d へ書き込みます。"
			% TARGET_SLOT
			+ " tools/seed_shark_test_save.sh から実行してください。"
		)
		get_tree().quit(1)
		return

	# tools/ 配下起動はサンドボックスになるため、明示的に解除する
	PlayerProgress._sandbox_mode = false
	PlayerProgress.set_active_save_slot(TARGET_SLOT, false)
	_apply_seed_state()
	PlayerProgress.save_game()

	var save_path := ProjectSettings.globalize_path(PlayerProgress.current_save_path())
	var access := PlayerProgress.fishing_spot_access_status("danger_reef")
	if not bool(access.get("ok", false)):
		push_error(
			"危険海域が解放されていません: %s"
			% String(access.get("message", access.get("reason", "unknown")))
		)
		get_tree().quit(1)
		return

	print("seed_shark_test_save: ok")
	print("  slot: %d" % TARGET_SLOT)
	print("  path: %s" % save_path)
	print("  level: %d" % PlayerProgress.level)
	print("  boats: %s" % ", ".join(PlayerProgress.owned_boats))
	print("  sea_chart_fragments: %d/3" % PlayerProgress.sea_chart_fragments)
	print("  equipped_rod: %s" % PlayerProgress.equipped_rod_id)
	print("  equipped_rig: %s" % PlayerProgress.equipped_rig_id)
	print("  owned_rigs: %s" % ", ".join(PlayerProgress.owned_rigs))
	print("  bait_fish: %s" % _inventory_summary())
	print("")
	print("ゲームを起動し、スロット%dを選んで「危険海域・鮫の根」へ向かってください。" % TARGET_SLOT)
	print("港の出港準備で餌魚を選んでから出航してください。")
	print("仕掛けの目安: nomase=小魚 / chokusen=イソメ / kani=岩ガニ（タックル屋で切替）")
	print("餌魚の目安: アジ=ホシザメ好物 / イワシ=群鳥系 / キハダ=高単価・大型向け")
	get_tree().quit(0)


func _apply_seed_state() -> void:
	PlayerProgress.level = 30
	PlayerProgress.exp = 0
	PlayerProgress.money = 50000
	PlayerProgress.inventory = {
		"aji": 5,
		"iwashi": 5,
		"mejina": 3,
		"kihada": 3,
	}
	PlayerProgress.caught_counts = {}
	PlayerProgress.spot_caught_counts = {}
	PlayerProgress.best_sizes = {}
	PlayerProgress.eaten_recipes = {}
	PlayerProgress.owned_rods = ["starter", "iso", "offshore", "big_game"]
	PlayerProgress.equipped_rod_id = "big_game"
	PlayerProgress.owned_rigs = ["sabiki", "uki", "chokusen", "nomase", "jigging", "kani"]
	PlayerProgress.equipped_rig_id = "nomase"
	PlayerProgress.owned_boats = ["skiff", "offshore_boat", "bluewater_boat"]
	PlayerProgress.pending_buff = {}
	PlayerProgress.play_seconds = 0.0
	PlayerProgress.quest_board = []
	PlayerProgress.quest_completed_count = 0
	PlayerProgress.sea_chart_fragments = PlayerProgress.SEA_CHART_FRAGMENT_MAX


func _inventory_summary() -> String:
	var parts: PackedStringArray = []
	for fish_id_variant in PlayerProgress.inventory.keys():
		var fish_id := String(fish_id_variant)
		var count := PlayerProgress.fish_count(fish_id)
		if count <= 0:
			continue
		var fish := GameData.get_fish(fish_id)
		var name := String(fish.get("name", fish_id))
		parts.append("%s x%d" % [name, count])
	parts.sort()
	return ", ".join(parts)
