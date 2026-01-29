extends Control

var file_path : String
@export var input_file_path : Button
@export var convert_format_option : OptionButton
@onready var ffmpeg: Node = $"ffmpeg funcs"


var file_types = {
	'image': ["jpg", "jpeg", "png", "bmp", "gif", "webp"],
	'video': ["mp4", "avi", "mov", "mkv", "webm", "flv", "wmv"],
	'audio': ["mp3", "wav", "flac", "aac", "ogg", "m4a"]
}

func _ready() -> void:
	var args = OS.get_cmdline_args()
	if args.size() > 1:
		_update_inputfile(args[1].strip_edges())
		print("Args: ", file_path)
	else:
		push_error("Invalid file path")
	

func _convert_pressed() -> void:
	ffmpeg.convert_video($MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs/Convert/Convert/Option.get_item_text($MarginContainer/VBoxContainer/SimpleFuncs/VideoFuncs/Convert/Convert/Option.get_selected_id()))


func _compress_pressed() -> void:
	show_windows_notification("Compressing done","Succesfyllu")


func _editfps_pressed() -> void:
	pass # Replace with function body.


func _extractaudio_pressed() -> void:
	ffmpeg.change_audio_bitrate_in_video(1000)


func _select_file_pressed() -> void:
	$MarginContainer/VBoxContainer/Header/FilePath/FileDialog.show()
func _on_file_selected(path: String) -> void:
	_update_inputfile(path)

func _update_inputfile(path: String) -> void:
	file_path = path
	input_file_path.text = path
	print("File selected: ", path)
	for i in file_types["video"]:
		convert_format_option.add_item(i)


func _on_settings_pressed() -> void:
	$MarginContainer/VBoxContainer/Bottom/Settings/Window.show()



func show_windows_notification(title: String, message: String):
	var command = "powershell"
	var args = [
		"-Command",
		"Add-Type -AssemblyName System.Windows.Forms; $notify = New-Object System.Windows.Forms.NotifyIcon; $notify.Icon = [System.Drawing.SystemIcons]::Information; $notify.BalloonTipTitle = '%s'; $notify.BalloonTipText = '%s'; $notify.Visible = $true; $notify.ShowBalloonTip(5000);" % [title, message]
	]
	
	var output = []
	var exit_code = OS.execute(command, args, output, true)
	
	if exit_code != 0:
		push_error("Failed to show notification")


func _on_options_close_requested() -> void:
	$MarginContainer/VBoxContainer/Bottom/Settings/Window.hide()
