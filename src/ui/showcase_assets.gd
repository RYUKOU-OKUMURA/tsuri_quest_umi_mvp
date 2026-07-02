class_name ShowcaseAssets
extends RefCounted


static func load_texture(path: String) -> Texture2D:
	if path.strip_edges().is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image := Image.new()
	if image.load(absolute_path) != OK:
		return null
	return ImageTexture.create_from_image(image)


static func texture_rect(path: String, stretch_mode := TextureRect.STRETCH_SCALE) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = load_texture(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = stretch_mode
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func texture_style(
	path: String,
	margins: Vector4,
	content_margins := Vector4(10.0, 8.0, 10.0, 8.0)
) -> StyleBoxTexture:
	var texture := load_texture(path)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margins.x
	style.texture_margin_top = margins.y
	style.texture_margin_right = margins.z
	style.texture_margin_bottom = margins.w
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.content_margin_left = content_margins.x
	style.content_margin_top = content_margins.y
	style.content_margin_right = content_margins.z
	style.content_margin_bottom = content_margins.w
	return style


static func atlas_icon(sheet_path: String, cell_size: float, icon_index: int) -> Texture2D:
	return atlas_icon_from_texture(load_texture(sheet_path), cell_size, icon_index)


static func atlas_icon_from_texture(sheet: Texture2D, cell_size: float, icon_index: int) -> Texture2D:
	if sheet == null or icon_index < 0:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(cell_size * float(icon_index), 0.0), Vector2(cell_size, cell_size))
	return atlas
