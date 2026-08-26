extends Control

enum PaintTools {
	Spray,
	Stamp,
	Select
}

@export var canvas_base_image: Texture2D
@export var canvas_border_image: Texture2D

@export var paint_colours: Array[Color]

@export_group("PaintTools")
@export_subgroup("Spray")
@export var spray_sprites: SheetTexture
@export var spray_max_slide_distance: float

var spray_active_sprites: SheetTexture

@export_subgroup("Stamp")
@export var stamp_sprites: SheetTexture
#@export var stamp_rotation_range

@export_subgroup("Select")
@export var select_max_sides: Vector2i
@export var select_max_size: int 

var canvas_image: Image

var active_paint_tool: PaintTools
var active_paint_color: Color

func _ready() -> void:
	canvas_image = Image.create_empty(canvas_base_image.get_width(),canvas_base_image.get_height(),false,5 as Image.Format)
	
	active_paint_tool = 0 as PaintTools
	_change_paint_tool()
	
	_update_canvas()


func _change_paint_tool():
	active_paint_color = paint_colours.pick_random()
	
	match active_paint_tool:
		PaintTools.Spray:
			print(active_paint_color)
			spray_active_sprites = spray_sprites.duplicate()
			var img = spray_active_sprites.atlas.get_image()
			for x in range(img.get_width()):
				for y in range(img.get_height()):
					img.set_pixel(x,y,img.get_pixel(x,y) * active_paint_color)
			spray_active_sprites.atlas = ImageTexture.create_from_image(img)


func _update_canvas():
	$Canvas.texture = ImageTexture.create_from_image(canvas_image)
@onready var canvas: TextureRect = $Canvas


func _gui_input(event: InputEvent) -> void:
	match active_paint_tool:
		PaintTools.Spray:
			if event is InputEventMouseMotion:
				if event.button_mask == 1:
					var pos = event.position
					canvas_image.blend_rect(spray_active_sprites.get_random_image(),Rect2i(Vector2i.ZERO,spray_sprites.get_size()),pos - spray_sprites.get_size()/2)
					_update_canvas()
					
