extends Node
## グローバル演出マネージャ（autoload「Juicer」）。
## - 画面揺れ（trauma モデル）。各画面は get_offset() を読んでルート位置に適用する。
## - ヒットストップ（短い全体一時停止で重さを演出）。
## gl_compatibility / どのレンダラでも動く（transform と SceneTree の paused のみ使用）。

const MAX_OFFSET := 10.0   # 720p での揺れ上限(px)。酔い注意。
const DECAY := 1.6         # trauma の減衰速度(1秒あたり)

var _trauma := 0.0
var _time := 0.0
var _freeze := 0.0
var _owns_tree_pause := false
var _noise := FastNoiseLite.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.frequency = 14.0
	_noise.seed = 1337


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func hit_stop(seconds: float) -> void:
	var duration := clampf(seconds, 0.0, 0.12)
	if duration <= 0.0:
		return
	_freeze = maxf(_freeze, duration)
	if not get_tree().paused:
		get_tree().paused = true
		_owns_tree_pause = true


func get_offset() -> Vector2:
	if _trauma <= 0.001:
		return Vector2.ZERO
	var s := _trauma * _trauma
	return Vector2(
		_noise.get_noise_3d(_time * 30.0, 0.0, 0.0),
		_noise.get_noise_3d(0.0, _time * 30.0, 99.0)
	) * MAX_OFFSET * s


func _process(delta: float) -> void:
	if _freeze > 0.0:
		_freeze -= delta
		if _freeze <= 0.0:
			_freeze = 0.0
			if _owns_tree_pause:
				get_tree().paused = false
			_owns_tree_pause = false
		return
	_time += delta
	_trauma = maxf(_trauma - delta * DECAY, 0.0)
