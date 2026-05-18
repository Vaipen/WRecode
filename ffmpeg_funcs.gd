extends Node

# --- Сигналы ---
signal ffmpeg_started
signal ffmpeg_finished

# --- Настройки ---
@export var devmode : bool = false
@onready var main: Control = $".."

# --- Состояние процесса ---
var exe_dir : String
var ffmpeg_path : String
var ffprobe_path : String
var ffmpeg_pid : int = -1
var ffmpeg_stdout: FileAccess
var total_duration : float = 0.0

# --- Данные для UI ---
var progress : float = 0.0
var fps : float = 0.0
var speed : float = 0.0
var bitrate : String = "0"
var current_time : float = 0.0
var eta : float = 0.0
var formated_eta : String = "00:00:00"

func _ready() -> void:
	if devmode:
		exe_dir = "E:/Godot/Projects/WRecode/"
	else:
		exe_dir = OS.get_executable_path().get_base_dir()
	
	ffmpeg_path = exe_dir.path_join("ffmpeg/bin/ffmpeg.exe")
	ffprobe_path = exe_dir.path_join("ffmpeg/bin/ffprobe.exe")

func _process(_delta) -> void:
	if ffmpeg_pid == -1: return
	_read_ffmpeg_output()
	if not OS.is_process_running(ffmpeg_pid):
		_finalize_process()

func _run_ffmpeg(output_path: String, custom_args: Array, input_path: String = main.file_path) -> void:
	_reset_stats()
	total_duration = get_duration_seconds(input_path)
	if total_duration <= 0: total_duration = 1.0 # Для фото
	
	var args: Array = ["-y", "-i", input_path]
	args.append_array(custom_args)
	args.append_array(["-progress", "pipe:1", output_path])
	
	ffmpeg_started.emit()
	var pipe = OS.execute_with_pipe(ffmpeg_path, args)
	if pipe.has("pid"):
		ffmpeg_pid = pipe["pid"]
		ffmpeg_stdout = pipe["stdio"]
	else:
		ffmpeg_finished.emit()

func _reset_stats():
	progress = 0.0; fps = 0.0; speed = 0.0; current_time = 0.0; formated_eta = "00:00:00"

func _read_ffmpeg_output() -> void:
	if ffmpeg_stdout == null: return
	while ffmpeg_stdout.get_error() == OK and ffmpeg_stdout.get_position() < ffmpeg_stdout.get_length():
		var line = ffmpeg_stdout.get_line().strip_edges()
		if line == "": break
		_parse_line(line)

func _parse_line(line: String) -> void:
	if line.begins_with("fps="): fps = line.get_slice("=", 1).to_float()
	elif line.begins_with("speed="): speed = max(0.001, line.get_slice("=", 1).replace("x", "").to_float())
	elif line.begins_with("bitrate="): bitrate = line.get_slice("=", 1).strip_edges()
	elif line.begins_with("out_time_ms="):
		current_time = line.get_slice("=", 1).to_float() / 1_000_000.0
		progress = clamp((current_time / total_duration) * 100.0, 0.0, 100.0)
		if speed > 0:
			eta = (total_duration - current_time) / speed
			formated_eta = format_time(eta)

func _finalize_process() -> void:
	ffmpeg_pid = -1; ffmpeg_stdout = null; progress = 100.0
	ffmpeg_finished.emit()

# --- Video ---
func convert_video(format: String): _run_ffmpeg(main.file_path.get_basename() + "." + format, ["-c", "copy"])
func change_fps(fps_val: String): _run_ffmpeg(main.file_path.get_basename() + "_" + fps_val + "fps." + main.file_path.get_extension(), ["-vf", "fps=" + fps_val])
func extract_audio(): _run_ffmpeg(main.file_path.get_basename() + ".mp3", ["-vn"])
func change_bitrate(kbps: String): _run_ffmpeg(main.file_path.get_basename() + "_" + kbps + "k." + main.file_path.get_extension(), ["-b:v", kbps + "k"])
func change_audio_bitrate_in_video(kbps: String): _run_ffmpeg(main.file_path.get_basename() + "_a" + kbps + "k." + main.file_path.get_extension(), ["-c:v", "copy", "-b:a", kbps + "k"])
func resize_video(size: String): _run_ffmpeg(main.file_path.get_basename() + "_" + str(size.replace(":","x")) + "." + main.file_path.get_extension(), ["-vf", "scale="+size])


func compress_video_by_size(target_size_mb: float):
	var input_path = main.file_path
	target_size_mb-=0.15
	var duration = get_duration_seconds(input_path)
	if duration <= 0: return
	var v_kbps = int((target_size_mb * 8192.0) / duration) - 128
	var log_file = input_path.get_basename() + "_2pass"
	_run_ffmpeg("NUL", ["-c:v", "libx264", "-b:v", str(v_kbps)+"k", "-pass", "1", "-passlogfile", log_file, "-an", "-f", "mp4"], input_path)
	await ffmpeg_finished
	_run_ffmpeg(input_path.get_basename() + "_compressed.mp4", ["-c:v", "libx264", "-b:v", str(v_kbps)+"k", "-pass", "2", "-passlogfile", log_file, "-c:a", "aac", "-b:a", "128k"], input_path)
	await ffmpeg_finished
	DirAccess.remove_absolute(log_file + "-0.log"); DirAccess.remove_absolute(log_file + "-0.log.mbtree")

# --- Audio ---
func convert_audio(format: String):
	var codec = "libmp3lame" if format == "mp3" else "aac"
	if format == "wav": codec = "pcm_s16le"
	elif format == "flac": codec = "flac"
	elif format == "ogg": codec = "libvorbis"
	_run_ffmpeg(main.file_path.get_basename() + "." + format, ["-c:a", codec])
func change_audio_bitrate(kbps: String): _run_ffmpeg(main.file_path.get_basename() + "_%sk."%[kbps]+main.file_path.get_extension(), ["-b:a", kbps + "k"])
func change_audio_samplerate(hz: String): _run_ffmpeg(main.file_path.get_basename() + "_%shz."%[str(hz.to_int())]+main.file_path.get_extension(), ["-ar", str(hz.to_int())])

# --- Image ---
func convert_image(format: String): _run_ffmpeg(main.file_path.get_basename() + "." + format, [])
func resize_image(size: String): _run_ffmpeg(main.file_path.get_basename() + "_%s."%[str(size.replace(":", "x"))] + main.file_path.get_extension(), ["-vf", "scale=" + size])
func compress_image(target_size_mb: float):
	if target_size_mb <= 0: return
	var file = FileAccess.open(main.file_path, FileAccess.READ)
	var current_size_mb = float(file.get_length()) / (1024.0 * 1024.0)
	
	# Считаем примерный уровень сжатия (q:v). 
	# Чем больше разница в размере, тем больше цифра q:v
	var ratio = current_size_mb / target_size_mb
	var estimated_q = clamp(int(ratio * 5.0), 2, 31) 
	
	var out_path = main.file_path.get_basename() + "_low.jpg"
	_run_ffmpeg(out_path, ["-q:v", str(estimated_q)])
	
# --- Utils ---
func get_duration_seconds(path: String) -> float:
	var output = []
	var code = OS.execute(ffprobe_path, ["-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", path], output, true)
	return output[0].strip_edges().to_float() if code == 0 and not output.is_empty() else 0.0

func format_time(seconds: float) -> String:
	return "%02d:%02d:%02d" % [int(seconds / 3600.0), int(fmod(seconds, 3600.0) / 60.0), int(fmod(seconds, 60.0))]
