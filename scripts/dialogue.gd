extends Control
class_name Dialogue

@onready var text_label = %text_label
@onready var buttons_container = %choices_container
@onready var char_label = %name_label
var text_path = "res://assets/dialogues/"

var locale
var dialogue_name
var dialogue_data #dictionary from json

var event_id: String = "0" #next scene id
var conditions = {} #bool conditions local to this scene, if null - check global
var results = {}

var player_scene
var speaker_scene

func _ready(): update_locale()

func init_dialogue_from_data(d_name, data):
	dialogue_name = d_name
	dialogue_data = data
	get_dialogue_data()
	set_event()

func init_dialogue_from_file(file_name, overwrite_conditions: Dictionary = {}):
	dialogue_name = file_name
	
	var file = FileAccess.open(text_path + dialogue_name + ".json", FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		text_label.text = "JSON parsing mistake"
		return
		
	dialogue_data = json.get_data()
	get_dialogue_data()
	conditions.merge(overwrite_conditions, true)
	set_event()
	
func get_dialogue_data():
	conditions = dialogue_data.get("conditions", {})
	results = dialogue_data.get("results", {})
	char_label.text = dialogue_data.get("char_name", {}).get(locale, "")
	
func set_event(id: String = "0", is_extra: bool = false):
	for b in buttons_container.get_children(): b.queue_free()
	if is_extra:
		text_label.text = id
		create_choice_button("...", {})
	else:
		if dialogue_data["events"].has(id):
			var event = dialogue_data["events"][id]
			if event.has("conditions"): #conditional event text
				var result = true
				for c in event["conditions"]:
					if !conditions.has(c) or conditions[c] != event["conditions"][c]:
						result = false
						break
				if result: text_label.text = event["true_text"][locale]
				else: text_label.text = event["false_text"][locale]
			else:
				text_label.text = event["text"][locale]
			var choices = check_conditions(event.get("choices", []))
			if choices.is_empty():
				create_choice_button("...", {})
			else:
				for choice in choices:
					create_choice_button(choice["text"][locale], choice.get("effects", {}))
			event_id = str(int(id) + 1)
		else:
			GameManager.finish_dialogue(player_scene, speaker_scene, self)
			
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
		if effects.is_empty(): set_event(event_id)
		else: apply_effects(effects))
	b.custom_minimum_size = Vector2(976, 0)
	b.add_theme_font_size_override("font_size", 40)
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buttons_container.add_child(b)
		
func apply_effects(effects: Dictionary):
	var jumping_scene = effects.get("jump", "")
	var showing_scene = effects.get("show", {}).get(locale, "")
	
	if effects.has("change_condition"):
		for condition in effects["change_condition"]:
			if conditions.has(condition):
				conditions[condition] = effects["change_condition"][condition]
	
	if effects.has("change_result"):
		for result in effects["change_result"]:
			if results.has(result):
				results[result] = effects["change_result"][result]
				
	if effects.has("finish_dialogue"):
		GameManager.finish_dialogue(player_scene, speaker_scene, self)
	else:
		if effects.has("stay"):
			set_stay(effects["stay"])
		elif showing_scene and jumping_scene:
			event_id = jumping_scene
			set_event(showing_scene, true)
		elif showing_scene and !jumping_scene:
			set_event(showing_scene, true) # god help us
		elif !showing_scene and jumping_scene:
			set_event(jumping_scene)
		else: set_event(event_id)
		
#this one practically leaves the same choices but changes the text
func set_stay(stay: Dictionary):
	event_id = str(int(event_id) - 1)
	if dialogue_data.events[event_id].has("conditions"):
		dialogue_data.events[event_id].erase("conditions")
		dialogue_data.events[event_id].erase("true_text")
		dialogue_data.events[event_id].erase("false_text")
	dialogue_data.events[event_id]["text"] = {locale: stay[locale]}
	set_event(event_id)
	
func update_locale(): locale = TranslationServer.get_locale().split("_")[0]
	
		
