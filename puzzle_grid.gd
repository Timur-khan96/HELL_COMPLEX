extends Node2D

signal no_turns

var explosion = load("res://scenes/effects/stone_explosion.tscn")

const GRID_ROWS = 8
const GRID_COLS = 8
const CELL_SIZE = 90
const STONE_TYPES = ["player", "enemy", "red", "blue", "green", "yellow", "orange", "purple"]
enum BONUS_TYPES {NONE, HORIZONTAL, VERTICAL}
var COLOR_CODES = [Color.from_rgba8(0,0,0).linear_to_srgb(),
					Color.from_rgba8(0,0,0).linear_to_srgb(),
					Color.from_rgba8(201,0,0).linear_to_srgb(),
					Color.from_rgba8(0,34,229).linear_to_srgb(), 
					Color.from_rgba8(39,132,0).linear_to_srgb(), 
					Color.from_rgba8(246,255,0).linear_to_srgb(), 
					Color.from_rgba8(255,158,22).linear_to_srgb(), 
					Color.from_rgba8(137,0,201).linear_to_srgb()]
var darkened_factor = 0.2

var textures = {}
var row_bonus_textures = {}
var col_bonus_textures = {}
var grid = []
var selected_vec = null # Vector2i but can be null
var hovered_vec = null # Vector2i but can be null

var has_player_made_turn = false
var last_swapped = []

var bg_alpha = 0.0

func _ready():
	var sprite_sheet = load("res://assets/textures/puzzle_textures.png")
	var line_bonus = preload("res://assets/textures/line_bonus_small.png")
	var sprite_size = Vector2i(90, 90)
	
	var i = 0
	for type in STONE_TYPES:
		var atlas_tex = AtlasTexture.new()
		atlas_tex.atlas = sprite_sheet
		atlas_tex.region = Rect2i(i * sprite_size.x, 0, sprite_size.x, sprite_size.y)
		textures[type] = atlas_tex
		i += 1
		if i > 1:
			row_bonus_textures[type] = create_colored_texture(line_bonus, COLOR_CODES[STONE_TYPES.find(type)])
			col_bonus_textures[type] = create_colored_texture(line_bonus, COLOR_CODES[STONE_TYPES.find(type)], true)
	
func init_puzzle(puzzle_grid):
	for row in range(GRID_ROWS):
		var row_data = []
		for col in range(GRID_COLS):
			var new_type
			if puzzle_grid[row][col].type == "random":
				new_type = STONE_TYPES[randi_range(2, 7)]
			else:
				new_type = puzzle_grid[row][col].type
				
			row_data.append({
				"type": new_type,
				"bonus_type": BONUS_TYPES.NONE,
				"grid_pos": Vector2i(col, row),
				"sprite_pos": Vector2(col, row) * CELL_SIZE,
				"is_moving": false,
			})
		grid.append(row_data)
		
	var tween = get_tree().create_tween()
	tween.tween_property(self, "bg_alpha", 0.8, 1.5) 
	#tween.tween_callback(_on_fade_complete)
	
func create_colored_texture(original_texture: Texture2D, base_color: Color, rotating: bool = false) -> ImageTexture:
	var image = original_texture.get_image()
	var darkened_color = base_color.darkened(darkened_factor)
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var tex_color = image.get_pixel(x, y)
			if tex_color.a < 0.1: continue
		
			if tex_color.r > 0.5 and tex_color.g > 0.5 and tex_color.b > 0.5:
				image.set_pixel(x, y, base_color)
			else:
				image.set_pixel(x, y, darkened_color)
	if rotating: image.rotate_90(CLOCKWISE)
	return ImageTexture.create_from_image(image)

func _draw():
	draw_rect(Rect2(Vector2.ZERO, Vector2(GRID_COLS * CELL_SIZE, GRID_ROWS * CELL_SIZE)), Color(0.3,
	0.3, 0.3, bg_alpha))
	var tex_scale = 1
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var cell = grid[row][col]
			draw_rect(Rect2(cell.grid_pos * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE)), Color(0,
			0, 0, bg_alpha), false, 2)
			if cell.type:
				var t = get_texture_by_bonus(cell.type, cell.bonus_type)
				var size = t.get_size() * tex_scale
				draw_texture_rect(t, Rect2(cell.sprite_pos, size), false)
	if selected_vec != null:
		var p = Vector2(selected_vec.x, selected_vec.y) * CELL_SIZE
		draw_rect(Rect2(p, Vector2(CELL_SIZE,CELL_SIZE)), Color.YELLOW, false, 2)
	if hovered_vec != null and hovered_vec != selected_vec:
		var p = Vector2(hovered_vec.x, hovered_vec.y) * CELL_SIZE
		draw_rect(Rect2(p, Vector2(CELL_SIZE, CELL_SIZE)), Color.LIGHT_BLUE, false, 2)
		
func get_texture_by_bonus(cell_type: String, bonus_type: BONUS_TYPES):
	match bonus_type:
		BONUS_TYPES.NONE: return textures[cell_type]
		BONUS_TYPES.HORIZONTAL: return row_bonus_textures[cell_type]
		BONUS_TYPES.VERTICAL: return col_bonus_textures[cell_type]
				
func _process(delta):
	if (is_grid_idle()):
		if !are_there_turns(): 
			no_turns.emit()
			queue_free()
		if !check_matches() and has_player_made_turn:
			swap_stones(last_swapped[0], last_swapped[1])
		last_swapped.clear()
		has_player_made_turn = false
	else:
		move_stones(delta)
		queue_redraw()
	apply_gravity()
	
func are_there_turns():
	for row in GRID_ROWS:
		for col in GRID_COLS:
			var curr_type = grid[row][col].type
			if col + 3 < GRID_COLS:
				if curr_type == grid[row][col+1].type:
					if curr_type == grid[row][col + 3].type: return true
			if col - 3 >= 0:
				if curr_type == grid[row][col-1].type:
					if curr_type == grid[row][col - 3].type: return true
			if row + 3 < GRID_ROWS:
				if curr_type == grid[row+1][col].type:
					if curr_type == grid[row+3][col].type: return true
			if row - 3 >= 0:
				if curr_type == grid[row-1][col].type:
					if curr_type == grid[row-3][col].type: return true
	return false
	
func is_grid_idle():
	for row in GRID_ROWS:
		for col in GRID_COLS:
			if grid[row][col].is_moving: return false
	return true
	
func check_matches():
	var match_found = false
	for i in GRID_ROWS:
		for j in GRID_COLS:
			var type = grid[i][j].type
			if type == "": continue
			var horizontal = j + 2 < GRID_COLS && (grid[i][j + 1].type == type && grid[i][j + 2].type == type)
			var vertical = i + 2 < GRID_ROWS && (grid[i + 1][j].type == type && grid[i + 2][j].type == type)
			if !horizontal && !vertical: continue
			
			var matched = {}
			match_found = true
			matched[Vector2i(j, i)] = grid[i][j].bonus_type
			var col = j + 1
			var row = i + 1
			if horizontal:
				while(col < GRID_COLS && grid[i][col].type == type):
					matched[Vector2i(col, i)] = grid[i][col].bonus_type
					check_matches_col(col, i, matched, type)
					col += 1
					
			if vertical:
				while row < GRID_ROWS && grid[row][j].type == type:
					matched[Vector2i(j, row)] = grid[row][j].bonus_type
					check_matches_row(row, j, matched, type)
					row += 1
					
			process_matched(matched, get_new_bonus(col - j >= 4, row - i >= 4, matched))
	return match_found
	
func get_new_bonus(is_horizontal, is_vertical, matched):
	var new_bonus = BONUS_TYPES.NONE
	var adding_bonus = has_player_made_turn
	if adding_bonus: 
		for m in matched: 
			if matched[m] != BONUS_TYPES.NONE:
				adding_bonus = false
				break
	if adding_bonus:
		if is_horizontal:
			new_bonus = BONUS_TYPES.HORIZONTAL
		elif is_vertical:
			new_bonus = BONUS_TYPES.VERTICAL
	return new_bonus
	
func process_matched(matched: Dictionary, new_bonus: BONUS_TYPES):
	var new_bonuses = true
	while new_bonuses:
		new_bonuses = false
		for coords in matched.keys():
			if matched[coords] != BONUS_TYPES.NONE:
				apply_bonus(grid[coords.y][coords.x], matched)
				matched[coords] = BONUS_TYPES.NONE
				new_bonuses = true
	
	var match_count = {}
	for coords in matched.keys():
		var cell = grid[coords.y][coords.x]
		match_count[cell.type] = match_count.get(cell.type, 0) + 1
		explode(cell.sprite_pos, cell.type)
		if last_swapped.has(cell) and new_bonus != BONUS_TYPES.NONE:
			cell.bonus_type = new_bonus
		else: cell.type = ""
	
func apply_bonus(cell: Dictionary, matched: Dictionary):
	if cell.bonus_type == BONUS_TYPES.NONE: return
	var cell_x = cell.grid_pos.x
	var cell_y = cell.grid_pos.y
	match cell.bonus_type:
		BONUS_TYPES.HORIZONTAL:
			for col in GRID_COLS: 
				matched[Vector2i(col, cell_y)] = grid[cell_y][col].bonus_type
		BONUS_TYPES.VERTICAL:
			for row in GRID_ROWS:
				matched[Vector2i(cell_x, row)] = grid[row][cell_x].bonus_type
	cell.bonus_type = BONUS_TYPES.NONE
	
func check_matches_row(row: int, col: int, matched: Dictionary, type):
	var has_matches = false
	if col + 2 < GRID_COLS:
		has_matches = grid[row][col + 1].type == type && grid[row][col + 2].type == type
	if col - 2 >= 0 && !has_matches:
		has_matches = grid[row][col - 1].type == type && grid[row][col - 2].type == type
	if col + 1 < GRID_COLS && col - 1 >= 0 && !has_matches:
		has_matches = grid[row][col + 1].type == type && grid[row][col - 1].type == type
	if !has_matches: return

	var new_col = col + 1
	while new_col < GRID_COLS && grid[row][new_col].type == type:
		matched[Vector2i(new_col, row)] = grid[row][new_col].bonus_type
		new_col += 1

	new_col = col - 1
	while new_col >= 0 && grid[row][new_col].type == type:
		matched[Vector2i(new_col, row)] = grid[row][new_col].bonus_type
		new_col -= 1

func check_matches_col(col: int, row: int, matched: Dictionary, type):
	var has_matches = false
	if row + 2 < GRID_ROWS:
		has_matches = grid[row + 1][col].type == type && grid[row + 2][col].type == type
	if row - 2 >= 0 && !has_matches:
		has_matches = grid[row - 1][col].type == type && grid[row - 2][col].type == type
	if row + 1 < GRID_ROWS && row - 1 >= 0 && !has_matches:
		has_matches = grid[row + 1][col].type == type && grid[row - 1][col].type == type
	if !has_matches: return

	var new_row = row + 1
	while new_row < GRID_ROWS && grid[new_row][col].type == type:
		matched[Vector2i(col, new_row)] = grid[new_row][col].bonus_type
		new_row += 1

	new_row = row - 1
	while new_row >= 0 && grid[new_row][col].type == type:
		matched[Vector2i(col, new_row)] = grid[new_row][col].bonus_type
		new_row -= 1
		
func apply_gravity():
	for row in range(GRID_ROWS - 2, -1, -1):  # Starting from second-to-last row
		for col in range(GRID_COLS):
			var cell = grid[row][col]
			var below = grid[row + 1][col]
			if below.type == "" and cell.type != "":
				below.type = cell.type
				below.bonus_type = cell.bonus_type
				below.is_moving = true
				below.sprite_pos = cell.sprite_pos
				
				cell.type = ""
				cell.bonus_type = BONUS_TYPES.NONE
				cell.is_moving = false
	for col in range(GRID_COLS):
		if grid[0][col].type == "":
			var new_type = STONE_TYPES[randi_range(2, 7)]
			grid[0][col].type = new_type
			grid[0][col].bonus_type = BONUS_TYPES.NONE
			grid[0][col].sprite_pos.y -= CELL_SIZE
			grid[0][col].is_moving = true
					
func move_stones(delta):
	const vel = 400
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			if grid[row][col].is_moving:
				var c = grid[row][col]
				var dest = c.grid_pos * CELL_SIZE
				if c.sprite_pos.x != dest.x:
					if c.sprite_pos.x > dest.x: c.sprite_pos.x -= vel * delta
					else: c.sprite_pos.x += vel * delta
					if abs(c.sprite_pos.x - dest.x) <= vel * delta:
						c.sprite_pos = dest;
						c.is_moving = false
				elif c.sprite_pos.y != dest.y:
					if c.sprite_pos.y > dest.y: c.sprite_pos.y -= vel * delta
					else: c.sprite_pos.y += vel * delta
					if abs(c.sprite_pos.y - dest.y) <= vel * delta:
						c.sprite_pos = dest;
						c.is_moving = false
	
func _input(event):
	if event is InputEventMouseMotion:
		var mouse_pos = get_local_mouse_position()
		var col = int(mouse_pos.x / CELL_SIZE)
		var row = int(mouse_pos.y / CELL_SIZE)
		
		if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
			hovered_vec = null
			queue_redraw()
		else:
			var new_hovered = Vector2i(col, row)
			if hovered_vec != new_hovered:
				hovered_vec = new_hovered
				queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_local_mouse_position()
		var col = int(mouse_pos.x / CELL_SIZE)
		var row = int(mouse_pos.y / CELL_SIZE)
		if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS: return
		
		if selected_vec:
			var sel_x = selected_vec.x
			var sel_y = selected_vec.y
			if (abs(col - sel_x) == 1 and row == sel_y) or (abs(row - sel_y) == 1 and col == sel_x):
				swap_stones(grid[row][col], grid[sel_y][sel_x])
				last_swapped = [grid[row][col], grid[sel_y][sel_x]]
				selected_vec = null
				has_player_made_turn = true
			else: selected_vec = grid[row][col].grid_pos
		else: selected_vec = grid[row][col].grid_pos
		queue_redraw()

func swap_stones(cell_a: Dictionary, cell_b: Dictionary):
	var temp_type = cell_a.type
	cell_a.type = cell_b.type
	cell_b.type = temp_type
	
	temp_type = cell_a.bonus_type
	cell_a.bonus_type = cell_b.bonus_type
	cell_b.bonus_type = temp_type
	
	var temp_pos = cell_a.sprite_pos
	cell_a.sprite_pos = cell_b.sprite_pos
	cell_b.sprite_pos = temp_pos
	
	cell_a.is_moving = true
	cell_b.is_moving = true
	
func explode(pos: Vector2, type: String):
	var e = explosion.instantiate()
	e.position = pos + Vector2(CELL_SIZE, CELL_SIZE) / 2
	
	var color = COLOR_CODES[STONE_TYPES.find(type)]
	var second_color = color.darkened(darkened_factor)
	color.a = 1.0
	second_color.a = 1.0
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, second_color)
	gradient.add_point(1.0, color)
	
	var g = GradientTexture1D.new()
	g.gradient = gradient
	g.resource_local_to_scene = true
	add_child(e)
	e.finished.connect(_on_explosion_finished.bind(e))
	e.process_material.color = color
	e.process_material.color_initial_ramp = g
	e.emitting = true
	
func _on_explosion_finished(e): e.queue_free()
