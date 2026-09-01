extends Control

enum PaintTools {
	Spray,
	Stamp,
	Select
}

var tool_difficulty := {
	PaintTools.Spray : 1.5,
	PaintTools.Stamp : .2,
}

@export var canvas_base_image: Texture2D
@export var canvas_border_image: Texture2D

@export var paint_colours: Array[Color]

@export_group("PaintTools")
@export_subgroup("Spray")
@export var spray_sprites: SheetTexture
@export var spray_max_distance: float = 10
var spray_last_position: Vector2

var spray_active_sprites: SheetTexture

@export_subgroup("Stamp")
@export var stamp_sprites: SheetTexture


var stamp_active_sprites: SheetTexture

@export_subgroup("Select")
@export var select_max_sides: Vector2i
@export var select_max_size: int 

var canvas_image: Image
var current_round_canvas_image: Image

var current_percentage: float
var current_goal_percentage: float
var complete_percentage: float
var current_time: int
var current_goal_time: int
var difficulty_multiplier: float

var active_paint_tool: PaintTools
var active_paint_color: Color

var update_time: bool = false

signal percentage_reached

var lifes_left: int
var lost_life: bool

var won: bool

func start() -> void:
	canvas_image = Image.create_empty(canvas_base_image.get_width(),canvas_base_image.get_height(),false,5 as Image.Format)
	_update_canvas()
	
	difficulty_multiplier = 1
	lifes_left = 3

	while true:
		$PercentageUpdateTimer.start()
		current_round_canvas_image = Image.create_empty(canvas_base_image.get_width(),canvas_base_image.get_height(),false,5 as Image.Format)
		active_paint_tool = randi_range(0,1) as PaintTools
		_change_paint_tool()
		current_goal_percentage = difficulty_multiplier * tool_difficulty[active_paint_tool] * 0.12 + 0.10
		current_goal_time = int(1/difficulty_multiplier * 100) + 200
		update_time = true
		@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
		mouse_filter = 0
		
		await percentage_reached
		if won:
			break
		
		$PercentageUpdateTimer.stop()
		update_time = false
		
		if current_time >= current_goal_time:
			lifes_left -= 1
			lost_life = true
		else:
			lost_life = false
		
		_update_pause_screen()
		$PauseScreen.show()
		
		@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
		mouse_filter = 2
		
		if complete_percentage >= 0.99:
			break
			
		await get_tree().create_timer(4).timeout
		
		$PauseScreen.hide()
		if lifes_left <= 0:
			break
		difficulty_multiplier += randf_range(0.02,0.10)
		current_time = 0
	
	if complete_percentage >= 0.99:
		$PercentageLabel.hide()
		$TimerLabel.hide()
		$Sprite2D.hide()
		$PauseScreen.hide()
		$WinScreen.show()
		await get_tree().create_timer(8).timeout
		$WinScreen.hide()
		
	elif lifes_left <= 0:
		$PercentageLabel.hide()
		$TimerLabel.hide()
		$Sprite2D.hide()
		$PauseScreen.hide()
		$LooseScreen.show()

func _process(delta: float) -> void:
	$Sprite2D.global_position = get_global_mouse_position()
	
	if update_time:
		@warning_ignore("narrowing_conversion")
		current_time += delta * 100
		$TimerLabel.text = str(current_time) + " time"


func _update_pause_screen():
	
	$PauseScreen/Label7.text = "(" + str(round(complete_percentage * 10000)/100) + "/100)"
	
	$PauseScreen/Label2.text = str(current_time) + " time"
	$PauseScreen/Label4.text = str(round(current_goal_percentage * 10000)/100) + "%"
	
	if lost_life:
		$PauseScreen/Label5.modulate = Color(0.753, 0.0, 0.0, 1.0)
		$PauseScreen/Label5.text = "that is not enough, you needed " + str(current_goal_time)
	else:
		$PauseScreen/Label5.modulate = Color(0.224, 0.851, 0.0, 1.0)
		$PauseScreen/Label5.text = "wow, you only needed " + str(current_goal_time) + " ... tryhard ;p"
	
	if lifes_left >= 3:
		$PauseScreen/Life1.show()
		$PauseScreen/Life2.show()
		$PauseScreen/Life3.show()
		$PauseScreen/Label6.hide()
	
	elif lifes_left <= 2:
		$PauseScreen/Life3.hide()
		if lifes_left <= 1:
			$PauseScreen/Life2.hide()
			if lifes_left <= 0:
				$PauseScreen/Life1.hide()
				$PauseScreen/Label6.show()


func _get_current_round_canvas_fill_percentage() -> float:
	
	var image = current_round_canvas_image.get_region(Rect2i(20,20,500,300))
	image.shrink_x2()
	
	var opaque_pixels := 0.
	for x in image.get_width():
		for y in image.get_height():
			if image.get_pixel(x,y).a >= 0.5:
				opaque_pixels += 1
	
	return opaque_pixels / (image.get_width() * image.get_height())
	
	
func _get_complete_canvas_fill_percentage() -> float:
	
	var image = canvas_image.get_region(Rect2i(20,20,500,300))
	image.shrink_x2()
	
	var opaque_pixels := 0.
	for x in image.get_width():
		for y in image.get_height():
			if image.get_pixel(x,y).a >= 0.5:
				opaque_pixels += 1
	
	return opaque_pixels / (image.get_width() * image.get_height())
	


func _change_paint_tool():
	active_paint_color = paint_colours.pick_random()
	
	match active_paint_tool:
		PaintTools.Spray:
			$Sprite2D.frame = 1
			spray_last_position = Vector2.ZERO
			spray_active_sprites = spray_sprites.duplicate()
			var img = spray_active_sprites.atlas.get_image()
			for x in range(img.get_width()):
				for y in range(img.get_height()):
					img.set_pixel(x,y,img.get_pixel(x,y) * active_paint_color)
			spray_active_sprites.atlas = ImageTexture.create_from_image(img)
		
		PaintTools.Stamp:
			$Sprite2D.frame = 0
			stamp_active_sprites = stamp_sprites.duplicate()
			var img = stamp_active_sprites.atlas.get_image()
			for x in range(img.get_width()):
				for y in range(img.get_height()):
					img.set_pixel(x,y,img.get_pixel(x,y) * active_paint_color)
			stamp_active_sprites.atlas = ImageTexture.create_from_image(img)


func _update_canvas():
	$Canvas.texture = ImageTexture.create_from_image(canvas_image)
	


func _gui_input(event: InputEvent) -> void:
	match active_paint_tool:
		PaintTools.Spray:
			if event is InputEventMouse:
				if event.button_mask == 1:
					var pos = event.position
					if spray_last_position:
						var vector =  pos - spray_last_position
						var dist = vector.length()
						for i in range(dist / spray_max_distance + 1):
							var between_pos = spray_last_position + vector / (dist / spray_max_distance) * i
							canvas_image.blend_rect(spray_active_sprites.get_random_image(),Rect2i(Vector2i.ZERO,spray_active_sprites.get_size()),between_pos - spray_active_sprites.get_size()/2)
							current_round_canvas_image.blend_rect(spray_active_sprites.get_random_image(),Rect2i(Vector2i.ZERO,spray_active_sprites.get_size()),between_pos - spray_active_sprites.get_size()/2)
					else:
						canvas_image.blend_rect(spray_active_sprites.get_random_image(),Rect2i(Vector2i.ZERO,spray_active_sprites.get_size()),pos - spray_active_sprites.get_size()/2)
						current_round_canvas_image.blend_rect(spray_active_sprites.get_random_image(),Rect2i(Vector2i.ZERO,spray_active_sprites.get_size()),pos - spray_active_sprites.get_size()/2)
				
					_update_canvas()
					spray_last_position = pos
	
		PaintTools.Stamp:
			if event is InputEventMouseButton:
				if event.button_mask == 1 and not event.is_echo():
					var pos = event.position
					canvas_image.blend_rect(stamp_active_sprites.get_random_image(),Rect2i(Vector2i.ZERO,stamp_active_sprites.get_size()),pos - stamp_active_sprites.get_size()/2)
					current_round_canvas_image.blend_rect(stamp_active_sprites.get_random_image(),Rect2i(Vector2i.ZERO,stamp_active_sprites.get_size()),pos - stamp_active_sprites.get_size()/2)
					_update_canvas()


func _on_percentage_update_timer_timeout() -> void:
	$PercentageLabel.text = str(round(_get_current_round_canvas_fill_percentage() * 10000)/100) + "% / "+  str(round(current_goal_percentage * 10000)/100) + "%"
	current_percentage = _get_current_round_canvas_fill_percentage()
	
	if current_percentage >= current_goal_percentage:
		complete_percentage = _get_complete_canvas_fill_percentage()
		percentage_reached.emit()
		
		
		
