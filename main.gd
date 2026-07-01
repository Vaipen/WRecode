extends Control

# --- Ссылки на узлы ---
var file_path : String
@export var input_file_path : Button
@export var convert_format_option : OptionButton
@onready var ffmpeg: Node = $"ffmpeg funcs"
@onready var m3progressbar: Control = $MarginContainer/VBoxContainer/Bottom/Progress/MarginContainer/WavyProgressBar
@onready var progressinfo: RichTextLabel = $MarginContainer/VBoxContainer/Bottom/Progress/progressinfo

# Состояние работы
var run : bool = false

# Типы файлов для фильтрации интерфейса
var file_types = {
	'image': ["jpg", "jpeg", "png", "bmp", "gif", "webp"],
	'video': ["mp4", "avi", "mov", "mkv", "flv", "wmv"],
	'audio': ["mp3", "wav", "flac", "aac", "ogg"]
}

var config = ConfigFile.new()
var config_path = "user://settings.cfg"
@onready var notify_checkbox: CheckBox = $MarginContainer/VBoxContainer/Bottom/Settings/Window/MarginContainer/VBoxContainer/NOTIFYWHENcomplete

func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(812,612))
	m3progressbar.modulate = Color.TRANSPARENT
	
	# Загружаем настройки и подключаем сигнал
	load_settings()
	notify_checkbox.toggled.connect(func(toggled_on: bool): save_settings())
	
	# Получаем ВСЕ аргументы
	var args = OS.get_cmdline_args()
	# Ищем путь к файлу среди переданных аргументов.
	# Когда файл перетаскивают на .bat или отправляют через Send To, он передается без --
	# Поэтому он попадает в get_cmdline_args(), а не в user_args.
	for arg in args:
		var clean_path = arg.replace("\\", "/").strip_edges()
		# Игнорируем путь самого экзешника и проверяем, существует ли файл
		if not clean_path.ends_with(".exe") and FileAccess.file_exists(clean_path) and args != null:
			_update_inputfile(clean_path)
			break

func save_settings() -> void:
	config.set_value("Settings", "notify_complete", notify_checkbox.button_pressed)
	config.save(config_path)

func load_settings() -> void:
	var err = config.load(config_path)
	if err == OK:
		notify_checkbox.button_pressed = config.get_value("Settings", "notify_complete", true)
	else:
		save_settings()

func _process(delta: float) -> void:
	if run:
		m3progressbar.progress = lerp(m3progressbar.progress, ffmpeg.progress/100, delta*5)
		m3progressbar.wave_speed = lerp(m3progressbar.wave_speed, ffmpeg.fps/80, delta*4)
		progressinfo.text = "FPS: %d | Bitrate: %s | ETA: %s" % [ffmpeg.fps, ffmpeg.bitrate, ffmpeg.formated_eta]
		DisplayServer.window_set_title("WRecode - %d%%" % int(ffmpeg.progress))

# --- ЛОГИКА ВЫБОРА ФАЙЛА ---

func _update_inputfile(path: String) -> void:
	if path == "":
		$"MarginContainer/VBoxContainer/Select file".show()
		$MarginContainer/VBoxContainer/fillemptyspase.show()
		$MarginContainer/VBoxContainer/SimpleFuncs.hide()
		return
	else:
		$"MarginContainer/VBoxContainer/Select file".hide()
		$MarginContainer/VBoxContainer/fillemptyspase.hide()
		$MarginContainer/VBoxContainer/SimpleFuncs.show()
	file_path = path
	input_file_path.text = path
	var ext = path.get_extension().to_lower()
	
	# Проверяем, поддерживается ли формат
	var is_supported = false
	for category in file_types.values():
		if ext in category:
			is_supported = true
			break
			
	if not is_supported:
		$"MarginContainer/VBoxContainer/not supported".show()
		$MarginContainer/VBoxContainer/SimpleFuncs.hide()
		return
	else:
		$"MarginContainer/VBoxContainer/not supported".hide()
		$MarginContainer/VBoxContainer/SimpleFuncs.show()
	
	# Ссылки на панели
	var vid_panel = $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs
	var aud_panel = $MarginContainer/VBoxContainer/SimpleFuncs/AudioFuncs
	var img_panel = $MarginContainer/VBoxContainer/SimpleFuncs/ImageFuncs
	
	# 1. Показываем нужную панель в зависимости от расширения
	vid_panel.visible = ext in file_types['video']
	aud_panel.visible = ext in file_types['audio']
	img_panel.visible = ext in file_types['image']
	
	# 2. Заполняем OptionButton нужными форматами
	_populate_formats(vid_panel, aud_panel, img_panel)
	
	# 3. Разблокируем кнопки, если нужно
	if vid_panel.visible:
		vid_panel.get_node("Compress/HBoxContainer/Function").disabled = false
		vid_panel.get_node("Compress/HBoxContainer/Option").editable = true

func _populate_formats(vid, aud, img):
	# Находим активный выпадающий список
	var current_option : OptionButton = null
	var formats = []
	
	if vid.visible:
		current_option = vid.get_node("Convert/HBoxContainer/Option")
		formats = file_types['video']
	elif aud.visible:
		current_option = aud.get_node("Convert/HBoxContainer/Option")
		formats = file_types['audio']
	elif img.visible:
		current_option = img.get_node("Convert/HBoxContainer/Option")
		formats = file_types['image']
	if current_option:
		current_option.clear()
		for f in formats: current_option.add_item(f)
		convert_format_option = current_option # Запоминаем для функции конвертации

# --- СИСТЕМНЫЕ СИГНАЛЫ ---

func _on_ffmpeg_funcs_ffmpeg_started():
	run = true
	create_tween().tween_property(m3progressbar, "modulate", Color(1,1,1,1), 1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	$Background.material.set("shader_parameter/u_speed", 1.5)

func _on_ffmpeg_funcs_ffmpeg_finished():
	run = false
	create_tween().tween_property(m3progressbar, "modulate", Color(1,1,1,0), 1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	$Background.material.set("shader_parameter/u_speed", 0.2)
	progressinfo.text = "[tornado radius=1 freq=-2]WRecode"
	DisplayServer.window_set_title("WRecode")
	if $MarginContainer/VBoxContainer/Bottom/Settings/Window/MarginContainer/VBoxContainer/NOTIFYWHENcomplete.button_pressed:
		$Sounds/Finish.play()





func _select_file_pressed(): $MarginContainer/VBoxContainer/Header/FilePath/FileDialog.show()
func _on_file_selected(path: String): _update_inputfile(path)
func _on_settings_pressed(): $MarginContainer/VBoxContainer/Bottom/Settings/Window.show()
func _on_options_close_requested(): $MarginContainer/VBoxContainer/Bottom/Settings/Window.hide()

func _show_notification(title, msg):
	var args = ["-Command", "Add-Type -AssemblyName System.Windows.Forms; $i=[System.Drawing.SystemIcons]::Information; $n=New-Object System.Windows.Forms.NotifyIcon; $n.Icon=$i; $n.BalloonTipTitle='%s'; $n.BalloonTipText='%s'; $n.Visible=$true; $n.ShowBalloonTip(5000);" % [title, msg]]
	OS.execute("powershell", args)


func _on_convert_pressed() -> void:
	var fmt = convert_format_option.get_item_text(convert_format_option.selected)
	if $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs.visible: 
		ffmpeg.convert_video(fmt)
	elif $MarginContainer/VBoxContainer/SimpleFuncs/AudioFuncs.visible: 
		ffmpeg.convert_audio(fmt)
	elif $MarginContainer/VBoxContainer/SimpleFuncs/ImageFuncs.visible:
		ffmpeg.convert_image(fmt)


func _on_compress_pressed() -> void:
	if $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs.visible: 
		var val = $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs/Compress/HBoxContainer/Option.text.strip_edges()
		if val == "" or float(val) <= 0: return
		ffmpeg.compress_video_by_size(float(val))
	elif $MarginContainer/VBoxContainer/SimpleFuncs/ImageFuncs.visible:
		var val = $MarginContainer/VBoxContainer/SimpleFuncs/ImageFuncs/Compress/HBoxContainer/Option.text.strip_edges()
		if val == "" or float(val) <= 0: return
		ffmpeg.compress_image(float(val))


func _on_editfps_pressed() -> void:
	if $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs.visible: 
		var val = $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs/EditFPS/HBoxContainer/Option.text.strip_edges()
		if val == "": return
		ffmpeg.change_fps(val)



func _on_resize_pressed() -> void:
	if $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs.visible: 
		var val = $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs/Resize/HBoxContainer/Option.text.strip_edges()
		if val == "": return
		ffmpeg.resize_video(val)
	elif $MarginContainer/VBoxContainer/SimpleFuncs/ImageFuncs.visible:
		var val = $MarginContainer/VBoxContainer/SimpleFuncs/ImageFuncs/Resize/HBoxContainer/Option.text.strip_edges()
		if val == "": return
		ffmpeg.resize_image(val)



func _on_audioextract_pressed() -> void:
	if $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs.visible: 
		ffmpeg.extract_audio()


func _on_changebitrate_pressed() -> void:
	if $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs.visible:
		var val = $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs/ChangeBitrate/HBoxContainer/Option.text.strip_edges()
		if val == "": return
		ffmpeg.change_bitrate(val)
	elif $MarginContainer/VBoxContainer/SimpleFuncs/AudioFuncs.visible:
		var val = $MarginContainer/VBoxContainer/SimpleFuncs/AudioFuncs/ChangeBitrate/HBoxContainer/Option.text.strip_edges()
		if val == "": return
		ffmpeg.change_audio_bitrate(val)


func _on_changeaudiobitrate_pressed() -> void:
	if $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs.visible: 
		var val = $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs/ChnageABitrate/HBoxContainer/Option.text.strip_edges()
		if val == "": return
		ffmpeg.change_audio_bitrate_in_video(val)


func _on_samplerate_pressed() -> void:
	if $MarginContainer/VBoxContainer/SimpleFuncs/AudioFuncs.visible:
		var val = $MarginContainer/VBoxContainer/SimpleFuncs/AudioFuncs/EditSampleRate/HBoxContainer/Option.text.strip_edges()
		if val == "": return
		ffmpeg.change_audio_samplerate(val)
	
