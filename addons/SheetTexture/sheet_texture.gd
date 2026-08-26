@tool
class_name SheetTexture
extends Texture2D

@export var atlas: Texture2D:
	set(value):
		atlas = value
		emit_changed()

@export var hframes: int = 1:
	set(value):
		hframes = max(1, value)
		emit_changed()

@export var vframes: int = 1:
	set(value):
		vframes = max(1, value)
		emit_changed()


# --- Frame Count & Layout Helpers ---

func get_frame_count() -> int:
	return hframes * vframes

func get_region(frame: int) -> Rect2:
	if not atlas: return Rect2()
	var w = atlas.get_width() / hframes
	var h = atlas.get_height() / vframes
	var col = frame % hframes
	var row = frame / hframes
	return Rect2(col * w, row * h, w, h)

# --- Image Fetching ---

func get_frame_image(frame: int) -> Image:
	if not atlas: return null
	var full_image := atlas.get_image()
	if not full_image or full_image.is_empty():
		return null
	return full_image.get_region(get_region(frame))

func get_random_image() -> Image:
	var count = get_frame_count()
	if count <= 0: return null
	return get_frame_image(randi() % count)


# --- Texture / Sprite Fetching ---

func get_sprite(frame: int) -> Texture2D:
	if not atlas: return null
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = atlas
	atlas_tex.region = get_region(frame)
	return atlas_tex

func get_random_sprite() -> Texture2D:
	var count = get_frame_count()
	if count <= 0: return null
	return get_sprite(randi() % count)


# --- Full Sheet-Level Helpers ---

func get_sheet_width() -> int:
	if not atlas: return 0
	return atlas.get_width()

func get_sheet_height() -> int:
	if not atlas: return 0
	return atlas.get_height()

func get_sheet_size() -> Vector2:
	if not atlas: return Vector2.ZERO
	return atlas.get_size()


# --- Required Texture2D Virtual Methods (Defaults to Frame 0) ---

func _get_width() -> int:
	if not atlas: return 0
	return atlas.get_width() / hframes

func _get_height() -> int:
	if not atlas: return 0
	return atlas.get_height() / vframes

func _get_rid() -> RID:
	if not atlas: return RID()
	return atlas.get_rid()

func _has_alpha() -> bool:
	if not atlas: return false
	return atlas.has_alpha()

func _get_image() -> Image:
	return get_frame_image(0)
