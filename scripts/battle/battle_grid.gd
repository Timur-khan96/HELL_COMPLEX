extends Node2D

signal got_matches(match_data: Dictionary)

var explosion = load("res://scenes/sprite_explosion.tscn")

const GRID_ROWS = 10
const GRID_COLS = 10
const CELL_SIZE = 90
const STONE_TYPES = ["red", "blue", "green", "yellow", "orange", "purple"]

var textures = {}
var grid = []
var selected_vec = null # Vector2i but can be null
var hovered_vec = null # Vector2i but can be null

var has_player_made_turn = false
var last_swapped = []

var bg_alpha = 0.0

func _ready():
	for color in STONE_TYPES:
		textures[color] = load("res://assets/textures/" + color + ".png")
	for row in range(GRID_ROWS):
		var row_data = []
		for col in range(GRID_COLS):
			row_data.append({
				"type": "",
				"grid_pos": Vector2i(col, row),
				"sprite_pos": Vector2(col, row) * CELL_SIZE,
				"is_moving": false,
			})
		grid.append(row_data)
		
	var tween = get_tree().create_tween()
	tween.tween_property(self, "bg_alpha", 0.8, 1.5) 
	#tween.tween_callback(_on_fade_complete)

func _draw():
	draw_rect(Rect2(Vector2.ZERO, Vector2(GRID_COLS * CELL_SIZE, GRID_ROWS * CELL_SIZE)), Color(0.3,
	0.3, 0.3, bg_alpha))
	var tex_scale = 0.35
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var cell = grid[row][col]
			draw_rect(Rect2(cell.grid_pos * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE)), Color(0,
			0, 0, bg_alpha), false, 2)
			if cell.type:
				var t = textures[cell.type]
				var size = t.get_size() * tex_scale
				draw_texture_rect(t, Rect2(cell.sprite_pos, size), false)
	if selected_vec:
		var p = Vector2(selected_vec.x, selected_vec.y) * CELL_SIZE
		draw_rect(Rect2(p, Vector2(CELL_SIZE,CELL_SIZE)), Color.YELLOW, false, 2)
	if hovered_vec and hovered_vec != selected_vec:
		var p = Vector2(hovered_vec.x, hovered_vec.y) * CELL_SIZE
		draw_rect(Rect2(p, Vector2(CELL_SIZE, CELL_SIZE)), Color.LIGHT_BLUE, false, 2)
				
func _process(delta):
	if (is_grid_idle()):
		if !check_matches() and has_player_made_turn:
			swap_stones(last_swapped[0], last_swapped[1])
		has_player_made_turn = false
	else:
		move_stones(delta)
		queue_redraw()
	apply_gravity()
	
func is_grid_idle():
	for row in GRID_ROWS:
		for col in GRID_COLS:
			if grid[row][col].is_moving: return false
	return true
	
func check_matches():
	var match_found = false
	var matched = {} #using dic to have unique keys and no repetetive cells
	for i in GRID_ROWS:
		for j in GRID_COLS:
			var type = grid[i][j].type
			if !type: continue
			var horizontal = j + 2 < GRID_COLS && (grid[i][j + 1].type == type && grid[i][j + 2].type == type)
			var vertical = i + 2 < GRID_ROWS && (grid[i + 1][j].type == type && grid[i + 2][j].type == type)
			if !horizontal && !vertical: continue
			match_found = true
			matched[grid[i][j]] = true
			if horizontal:
				var col = j + 1
				while(col < GRID_COLS && grid[i][col].type == type):
					matched[grid[i][col]] = true
					check_matches_col(col, matched, type)
					col += 1
			if vertical:
				var row = i + 1
				while row < GRID_ROWS && grid[row][j].type == type:
					matched[grid[row][j]] = true
					check_matches_row(row, matched, type)
					row += 1
	if match_found:
		var match_count = {}
		for cell in matched.keys():
			match_count[cell.type] = match_count.get(cell.type, 0) + 1
			explode(cell.sprite_pos, textures[cell.type])
			cell.type = ""
		got_matches.emit(match_count)
	return match_found
	
func check_matches_row(row: int, matched: Dictionary, type):
	var col = matched.keys().back().grid_pos.x #-1 returns last element
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
		matched[grid[row][new_col]] = true
		new_col += 1

	new_col = col - 1
	while new_col >= 0 && grid[row][new_col].type == type:
		matched[grid[row][new_col]] = true
		new_col -= 1

func check_matches_col(col: int, matched: Dictionary, type):
	var row = matched.keys().back().grid_pos.y
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
		matched[grid[new_row][col]] = true
		new_row += 1

	new_row = row - 1
	while new_row >= 0 && grid[new_row][col].type == type:
		matched[grid[new_row][col]] = true
		new_row -= 1
		
func explode(pos: Vector2, texture: Texture2D):
	var e = explosion.instantiate()
	e.position = pos + Vector2(CELL_SIZE, CELL_SIZE) / 2
	e.process_material.set_shader_parameter("emission_box_extents",
	Vector3(CELL_SIZE / 2,CELL_SIZE / 2,1))
	e.process_material.set_shader_parameter("sprite", texture)
	add_child(e)
	e.emitting = true
			
func apply_gravity():
	for row in range(GRID_ROWS - 2, -1, -1):  # Starting from second-to-last row
		for col in range(GRID_COLS):
			var cell = grid[row][col]
			var below = grid[row + 1][col]
			if below.type == "" and cell.type != "":
				below.type = cell.type
				below.is_moving = true
				below.sprite_pos = cell.sprite_pos
				
				cell.type = ""
				cell.is_moving = false
	for col in range(GRID_COLS):
		if grid[0][col].type == "":
			var new_type = STONE_TYPES[randi() % STONE_TYPES.size()]
			grid[0][col].type = new_type
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
	
	var temp_pos = cell_a.sprite_pos
	cell_a.sprite_pos = cell_b.sprite_pos
	cell_b.sprite_pos = temp_pos
	
	cell_a.is_moving = true
	cell_b.is_moving = true
