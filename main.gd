extends Control

# --- Ссылки на узлы ---
var file_path : String
@export var input_file_path : Button
@export var convert_format_option : OptionButton
@onready var ffmpeg: Node = $"ffmpeg funcs"
@onready var progressbar: ProgressBar = $MarginContainer/VBoxContainer/Bottom/Progress/progressbar
@onready var progressinfo: RichTextLabel = $MarginContainer/VBoxContainer/Bottom/Progress/progressinfo

# Состояние работы
var run : bool = false

# Типы файлов для фильтрации интерфейса
var file_types = {
	'image': ["jpg", "jpeg", "png", "bmp", "gif", "webp"],
	'video': ["mp4", "avi", "mov", "mkv", "webm", "flv", "wmv"],
	'audio': ["mp3", "wav", "flac", "aac", "ogg", "m4a"]
}

func _ready() -> void:
	progressbar.hide()
	# Если файл был передан через аргументы запуска
	var args = OS.get_cmdline_args()
	if args.size() > 1: _update_inputfile(args[1].strip_edges())

func _process(_delta: float) -> void:
	if run:
		progressbar.value = ffmpeg.progress
		progressinfo.text = "FPS: %d | Bitrate: %s | ETA: %s" % [ffmpeg.fps, ffmpeg.bitrate, ffmpeg.formated_eta]
		DisplayServer.window_set_title("WRecode - %d%%" % int(ffmpeg.progress))

# --- ЛОГИКА ВЫБОРА ФАЙЛА ---

func _update_inputfile(path: String) -> void:
	if path == "": return
	file_path = path
	input_file_path.text = path
	var ext = path.get_extension().to_lower()
	
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
	progressbar.show()
	$Background.material.set("shader_parameter/u_speed", 1.5)

func _on_ffmpeg_funcs_ffmpeg_finished():
	run = false
	progressbar.hide()
	$Background.material.set("shader_parameter/u_speed", 0.2)
	DisplayServer.window_set_title("WRecode")
	if $MarginContainer/VBoxContainer/Bottom/Settings/Window/MarginContainer/VBoxContainer/NOTIFYWHENcomplete.button_pressed:
		_show_notification("WRecode", "Task Finished!")

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
	var fmt = convert_format_option.get_item_text(convert_format_option.selected)
	if $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs.visible: 
		ffmpeg.compress_video_by_size(fmt)
	elif $MarginContainer/VBoxContainer/SimpleFuncs/ImageFuncs.visible:
		ffmpeg.compress_image(fmt)


func _on_editfps_pressed() -> void:
	var fmt = convert_format_option.get_item_text(convert_format_option.selected)
	if $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs.visible: 
		ffmpeg.change_fps(fmt)



func _on_resize_pressed() -> void:
	var fmt = convert_format_option.get_item_text(convert_format_option.selected)
	if $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs.visible: 
		ffmpeg.resize_video(fmt)
	elif $MarginContainer/VBoxContainer/SimpleFuncs/ImageFuncs.visible:
		ffmpeg.resize_image(fmt)



func _on_audioextract_pressed() -> void:
	if $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs.visible: 
		ffmpeg.resize_video()


func _on_changebitrate_pressed() -> void:
	var fmt = convert_format_option.get_item_text(convert_format_option.selected)
	if $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs.visible: 
		ffmpeg.change_bitrate(fmt)
	elif $MarginContainer/VBoxContainer/SimpleFuncs/AudioFuncs.visible:
		ffmpeg.change_audio_bitrate(fmt)


func _on_changeaudiobitrate_pressed() -> void:
	var fmt = convert_format_option.get_item_text(convert_format_option.selected)
	if $MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs.visible: 
		ffmpeg.change_audio_bitrate_in_video(fmt)


func _on_samplerate_pressed() -> void:
	var fmt = convert_format_option.get_item_text(convert_format_option.selected)
	if $MarginContainer/VBoxContainer/SimpleFuncs/AudioFuncs.visible:
		ffmpeg.change_audio_samplerate(fmt)
	
