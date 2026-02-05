extends Panel
var m : bool = false
var windus : Vector2i


func _input(event):
	if Input.is_action_pressed("lmb") and m:
		get_window().position = windus + Vector2i(get_global_mouse_position().x,get_global_mouse_position().y)
	if m and Input.is_action_just_released("lmb"):
		m = false
		
func _on_mouse_entered():
	m = true
	
func _on_close_pressed():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _on_gui_input(event):
	windus = get_window().position - Vector2i(get_global_mouse_position().x,get_global_mouse_position().y)


func _on_mouse_exited():
	if Input.is_action_pressed("lmb"):
		if Input.is_action_just_released("lmb"):
			m = false
	else:
		m = false


func _on_info_mouse_entered() -> void:
	create_tween().tween_property($PanelContainer/VBoxContainer/info,"modulate",Color(1,1,1,1),1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
func _on_info_mouse_exited() -> void:
	create_tween().tween_property($PanelContainer/VBoxContainer/info,"modulate",Color(1,1,1,0.15),1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
