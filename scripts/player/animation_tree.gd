extends AnimationTree

func play_anim(anim_name):
	match anim_name:
		"idle":
			set("parameters/add_move/add_amount", 0)
		"move":
			set("parameters/add_move/add_amount", 1)
		"attack":
			set("parameters/attack_anim/request", 
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		"die":
			set("parameters/blend_die/blend_amount", 1)
		"fight_begin":
			set("parameters/add_fight/add_amount", 1)
			
func stop_anim(anim_name):
	match anim_name:
		"move":
			set("parameters/add_move/add_amount", 0)
		"fight_begin":
			set("parameters/add_fight/add_amount", 0)
	
