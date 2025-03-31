extends Control

var puzzle_scene = load("res://puzzle_grid.tscn")

const tile_types = ["random", "player", "enemy", "red", "blue", "green", "yellow", "orange", "purple"]
var tile_textures = {}

@onready var grid_container = $GridContainer

@export var ROWS: int = 8
@export var COLS: int = 8

const CELL_SIZE = 90
var grid = []

var playing_puzzle = null

func _ready():
	var i = 0
	var sprite_sheet = load("res://assets/textures/puzzle_textures.png")
	var sprite_size = Vector2i(90, 90)
	for type in tile_types:
		if type == "random":
			tile_textures["random"] = load("res://assets/textures/mix_board.png")
		else:
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = sprite_sheet
			atlas_tex.region = Rect2i(i * sprite_size.x, 0, sprite_size.x, sprite_size.y)
			tile_textures[type] = atlas_tex
			i += 1
	
	
	grid_container.columns = COLS
	for row in range(ROWS):
		var row_data = []
		for col in range(COLS):
			var cell_node = TextureButton.new()
			cell_node.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			cell_node.texture_normal = load("res://assets/textures/mix_board.png")
			cell_node.pressed.connect(_on_cell_pressed.bind(row, col))
			cell_node.ignore_texture_size = true
			cell_node.stretch_mode = TextureButton.STRETCH_SCALE
			grid_container.add_child(cell_node)
			row_data.append({
				"type": "random",
				"grid_pos": Vector2i(col, row),
				"node": cell_node
			})
		grid.append(row_data)
		
func _on_cell_pressed(row, col):
	var cell = grid[row][col]
	var current_type_index = tile_types.find(cell["type"])
	var new_type = tile_types[(current_type_index + 1) % tile_types.size()]
	cell["type"] = new_type
	cell["node"].texture_normal = tile_textures[new_type]
	
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()
		
func _on_play_button_pressed():
	if playing_puzzle != null: playing_puzzle.queue_free()
	var puzzle_node = puzzle_scene.instantiate()
	add_child(puzzle_node)
	puzzle_node.init_puzzle(grid)
	playing_puzzle = puzzle_node
	grid_container.hide()
	%play_button.text = "retry"

func _on_stop_button_pressed():
	if playing_puzzle == null: return
	playing_puzzle.queue_free()
	grid_container.show()
