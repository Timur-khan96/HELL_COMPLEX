extends Control
class_name TextScene

signal scene_finished

@onready var text_label = %scene_text
@onready var image_rect = %image_rect
@onready var buttons_container = %choices_container
var text_path = "res://assets/text_scenes/"
var image_path = "res://assets/text_scenes_pictures/"

var locale #TO DO change translation logic
var scene_name
var scene_data #dictionary from json

var scene_id: String = "0" #next scene id
var conditions = {} #bool conditions local to this scene, if not - check global

func _ready():
	update_locale()
	set_stats_text()

func init_scene_from_data(s_name, data, image_name: String = "default"):
	image_rect.texture = load(image_path + image_name + ".png")
	scene_name = s_name
	scene_data = data
	conditions = scene_data.get("conditions", {})
	set_scene()

func init_scene_from_file(file_name, image_name: String = "default"):
	image_rect.texture = load(image_path + image_name + ".png")
	scene_name = file_name
	
	var file = FileAccess.open(text_path + scene_name + ".json", FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		text_label.text = "JSON parsing mistake"
		return
		
	scene_data = json.get_data()
	conditions = scene_data.get("conditions", {})
	set_scene()
	
func set_stats_text():
	%stats_label.text = tr("HEALTH") + ": " + str(GameManager.player_health)
	%stats_label.text += "/" + str(GameManager.player_max_health) + "\n"
	%stats_label.text += GameManager.player_stats._to_string()
	
func set_scene(id: String = "0", is_extra: bool = false):
	for b in buttons_container.get_children(): b.queue_free()
	%scene_text_scroll.set_v_scroll(0)
	%choices_scroll.set_v_scroll(0)
	if is_extra:
		text_label.text = id
		create_choice_button("...", {})
	else:
		if scene_data["scenes"].has(id):
			var scene = scene_data["scenes"][id]
			if scene.has("image"): 
				image_rect.texture = load(image_path + scene["image"] + ".png")
			
			text_label.text = scene["text"][locale]
			var choices = check_conditions(scene.get("choices", []))
			if choices.is_empty():
				create_choice_button("...", {})
			else:
				for choice in choices:
					create_choice_button(choice["text"][locale], choice.get("effects", {}))
			scene_id = str(int(id) + 1)
		else:
			scene_finished.emit(scene_name)
			
func check_conditions(choices: Array):
	if choices.is_empty(): return choices
	var choices_to_erase = []
	for choice in choices:
		if choice.has("conditions"):
			for condition in choice["conditions"]:
				if conditions.has(condition):
					if choice["conditions"][condition] != conditions[condition]:
						choices_to_erase.append(choice)
	for c in choices_to_erase: 
		choices.erase(c)
	return choices
		
func create_choice_button(text: String, effects: Dictionary):
	var b = Button.new()
	b.text = text
	b.pressed.connect(func():
		if effects.is_empty(): set_scene(scene_id)
		else: apply_effects(effects))
	b.custom_minimum_size = Vector2(1292, 0)
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buttons_container.add_child(b)
		
func apply_effects(effects: Dictionary):
	var jumping_scene = effects.get("jump", "")
	var showing_scene = effects.get("show", {}).get(locale, "")
	if effects.has("change_skill"):
		for skill in effects["change_skill"]:
			GameManager._on_skill_changed(skill, effects["change_skill"][skill])
		set_stats_text()
	if effects.has("change_condition"):
		for condition in effects["change_condition"]:
			if conditions.has(condition):
				conditions[condition] = effects["change_condition"][condition]
	
	if showing_scene and jumping_scene:
		scene_id = jumping_scene
		set_scene(showing_scene, true)
	elif showing_scene and !jumping_scene:
		set_scene(showing_scene, true) # god help us
	elif !showing_scene and jumping_scene:
		set_scene(jumping_scene)
	else: set_scene(scene_id)
	
func update_locale(): locale = TranslationServer.get_locale().split("_")[0]
	
