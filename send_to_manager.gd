extends Node


# Всё вычисляется один раз при старте — не хардкодим ничего
var _exe_path: String
var _exe_name: String  # "WRecodeApp" без .exe
var _bat_path: String

func _ready() -> void:
	_exe_path = OS.get_executable_path()                        # C:\tools\WRecodeApp.exe
	_exe_name = _exe_path.get_file().get_basename()             # WRecodeApp
	
	var sendto := OS.get_environment("APPDATA") \
		+ "\\Microsoft\\Windows\\SendTo"
	_bat_path = sendto + "\\" + _exe_name + ".bat"     # WRecodeApp convert.bat
	
	if is_installed():
		print("exist")
		$"../First Install".queue_free()
	else:
		$"../First Install".show()
		$"../First Install/SendToNoficator".show()
		$"../First Install/Blur".show()

func install() -> void:
	# Папка SendTo обычно есть, но на всякий случай
	var _dir = DirAccess.open("user://")
	if _dir:
		_dir.make_dir_recursive(_bat_path.get_base_dir())

	var bat_content := (
        "@echo off\r\n"
		+ "chcp 1251 > nul\r\n"
		+ "\"" + _exe_path + "\" %*\r\n"
	)

	var file := FileAccess.open(_bat_path, FileAccess.WRITE)
	if file:
		file.store_string(bat_content)
		file.close()
		
		create_tween().tween_property($"../First Install/SendToNoficator","position", Vector2(0,$"../First Install/SendToNoficator".position.y+80),1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		create_tween().tween_property($"../First Install/SendToNoficator","modulate", Color.TRANSPARENT,1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		await get_tree().create_timer(1).timeout
		
		$"../First Install/HowTo".modulate = Color.TRANSPARENT
		$"../First Install/HowTo".show()
		create_tween().tween_property($"../First Install/HowTo","position", Vector2(0,0),1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		create_tween().tween_property($"../First Install/HowTo","modulate", Color.WHITE ,1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
		print("Установлено: ", _bat_path)
	else:
		push_error("Не удалось создать файл: " + _bat_path)


func uninstall() -> void:
	if FileAccess.file_exists(_bat_path):
		var _dir = DirAccess.open("user://")
		if _dir and _dir.remove(_bat_path) == OK:
			print("Удалено: ", _bat_path)
		else:
			push_error("Ошибка при удалении: " + _bat_path)
	else:
		print("Файл не найден: ", _bat_path)


func is_installed() -> bool:
	return FileAccess.file_exists(_bat_path)


func _on_buttoninstall_pressed() -> void:
	install()

func _on_buttondelete_pressed() -> void:
	uninstall()


func _on_buttonfinal_pressed() -> void:
	create_tween().tween_property($"../First Install/Blur".material,"shader_parameter/strength", 0.0,1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property($"../First Install/Blur".material,"shader_parameter/mix_percentage", 0.0,1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property($"../First Install","modulate", Color.TRANSPARENT,1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property($"../First Install/HowTo","position", Vector2(0,10),1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await get_tree().create_timer(1).timeout
	$"../First Install".queue_free()
