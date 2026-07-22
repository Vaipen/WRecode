extends Node

# --- Сигналы ---
signal ffmpeg_started
signal ffmpeg_finished
signal operation_done            # весь процесс над файлом завершён (все проходы)
signal gpu_detected(vendor: int, name: String)  # GPU найден: vendor (0=None,1=NVIDIA,2=AMD,3=Intel), name

# --- Настройки ---
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

# --- Управление сигналами ---
var _suppress_op_done: bool = false   # подавление operation_done (для multi-pass операций)

# --- GPU Acceleration ---
enum GPU { NONE, NVIDIA, AMD, INTEL }
var detected_gpu: GPU = GPU.NONE
var gpu_name: String = ""
var use_gpu: bool = false

# --- Compression Settings (populated by main.gd) ---
var pixels_per_kbps: float = 800.0
var min_scale_factor: float = 0.5

func _ready() -> void:
	if OS.has_feature("editor"):
		exe_dir = ProjectSettings.globalize_path("res://")
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
		var should_emit_op = not _suppress_op_done
		if should_emit_op:
			operation_done.emit()

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
	var should_emit_op = not _suppress_op_done
	ffmpeg_finished.emit()
	if should_emit_op:
		operation_done.emit()

# --- GPU Detection ---

func detect_gpu() -> void:
	var output: Array[String] = []
	var code := OS.execute("powershell", [
		"-Command",
		"Get-CimInstance Win32_VideoController | Select-Object Name, AdapterCompatibility, AdapterRAM | ConvertTo-Json"
	], output, true)
	
	if code != 0 or output.is_empty():
		gpu_detected.emit(GPU.NONE, "")
		return
	
	var json_str := ""
	for line in output:
		json_str += line
	
	var json = JSON.parse_string(json_str)
	if json == null:
		gpu_detected.emit(GPU.NONE, "")
		return
	
	var gpus: Array = json if json is Array else [json]
	
	var best_ram: int = -1
	var best_priority: int = 99
	
	for g in gpus:
		var gpu_dev_name: String = g.get("Name", "")
		var ram: int = int(g.get("AdapterRAM", 0))
		var upper := gpu_dev_name.to_upper()
		
		var gpu_type := GPU.NONE
		var priority := 99
		
		if "NVIDIA" in upper or "GEFORCE" in upper or "QUADRO" in upper or "RTX" in upper:
			gpu_type = GPU.NVIDIA; priority = 1
		elif "AMD" in upper or "RADEON" in upper:
			gpu_type = GPU.AMD; priority = 2
		elif "INTEL" in upper or "UHD" in upper or "IRIS" in upper or "ARC" in upper:
			gpu_type = GPU.INTEL; priority = 3
		
		if gpu_type != GPU.NONE and priority < best_priority:
			best_priority = priority
			best_ram = ram
			detected_gpu = gpu_type
			gpu_name = gpu_dev_name
		elif gpu_type != GPU.NONE and priority == best_priority and ram > best_ram:
			# Same vendor tier — pick the one with more VRAM (likely dGPU vs iGPU)
			best_ram = ram
			gpu_name = gpu_dev_name
	
	gpu_detected.emit(detected_gpu, gpu_name)

func get_hw_encoder() -> String:
	match detected_gpu:
		GPU.NVIDIA: return "h264_nvenc"
		GPU.AMD: return "h264_amf"
		GPU.INTEL: return "h264_qsv"
	return "libx264"

func get_hw_encoder_params() -> Array:
	match detected_gpu:
		GPU.NVIDIA: return ["-preset", "p4", "-tune", "hq"]
		GPU.AMD: return ["-quality", "quality"]
		GPU.INTEL: return ["-preset", "medium"]
	return []

func _build_video_encode_args(base_args: Array) -> Array:
	"""Prepends hardware encoder args if GPU acceleration is enabled."""
	if use_gpu and detected_gpu != GPU.NONE:
		var hw_args: Array = ["-c:v", get_hw_encoder()]
		hw_args.append_array(get_hw_encoder_params())
		hw_args.append_array(base_args)
		return hw_args
	return base_args

# --- Video ---

func convert_video(format: String):
	_run_ffmpeg(main.file_path.get_basename() + "." + format, ["-c", "copy"])

func change_fps(fps_val: String):
	var args := _build_video_encode_args(["-vf", "fps=" + fps_val])
	_run_ffmpeg(
		main.file_path.get_basename() + "_" + fps_val + "fps." + main.file_path.get_extension(),
		args
	)

func extract_audio():
	_run_ffmpeg(main.file_path.get_basename() + ".mp3", ["-vn"])

func change_bitrate(kbps: String):
	var args := _build_video_encode_args(["-b:v", kbps + "k"])
	_run_ffmpeg(
		main.file_path.get_basename() + "_" + kbps + "k." + main.file_path.get_extension(),
		args
	)

func change_audio_bitrate_in_video(kbps: String):
	_run_ffmpeg(
		main.file_path.get_basename() + "_a" + kbps + "k." + main.file_path.get_extension(),
		["-c:v", "copy", "-b:a", kbps + "k"]
	)

func resize_video(size: String):
	var scale_filter: String
	var suffix: String = size.replace(":", "x")
	
	if size.begins_with("x"):
		# Уменьшение в N раз: x2 → половина, x3 → треть и т.д.
		var factor = size.substr(1).to_float()
		if factor <= 0:
			return
		var res = get_video_resolution(main.file_path)
		if res.width <= 0 or res.height <= 0:
			printerr("resize_video: не удалось получить разрешение исходного видео")
			return
		var new_w := int(res.width / factor)
		var new_h := int(res.height / factor)
		if new_w % 2 != 0: new_w += 1
		if new_h % 2 != 0: new_h += 1
		scale_filter = "scale=%d:%d" % [new_w, new_h]
		suffix = size
	else:
		scale_filter = "scale=" + size
	
	var args := _build_video_encode_args(["-vf", scale_filter])
	_run_ffmpeg(
		main.file_path.get_basename() + "_" + suffix + "." + main.file_path.get_extension(),
		args
	)


func compress_video_by_size(target_size_mb: float):
	var input_path = main.file_path
	target_size_mb -= 0.15  # резерв под аудио
	if target_size_mb <= 0:
		return
	
	var duration := get_duration_seconds(input_path)
	if duration <= 0:
		return
	
	var res := get_video_resolution(input_path)
	if res.width <= 0 or res.height <= 0:
		printerr("compress_video_by_size: не удалось получить разрешение видео")
		return
	
	var fps_val := get_video_fps(input_path)
	
	# Общий доступный битрейт (kbps)
	var total_kbps := (target_size_mb * 8192.0) / duration
	var audio_kbps := 128.0
	var v_kbps := total_kbps - audio_kbps
	if v_kbps <= 0:
		return
	
	# Оптимальное разрешение: 400 пикселей на 1 kbps при 30fps (баланс: выше разрешение, ниже битрейт)
	var actual_pixels_per_kbps := pixels_per_kbps * 30.0 / fps_val
	var target_pixels := v_kbps * actual_pixels_per_kbps
	var orig_pixels = res.width * res.height
	
	var scale_factor := sqrt(target_pixels / orig_pixels)
	scale_factor = clamp(scale_factor, min_scale_factor, 1.0)
	
	var new_w := int(res.width * scale_factor)
	var new_h := int(res.height * scale_factor)
	if new_w % 2 != 0: new_w += 1
	if new_h % 2 != 0: new_h += 1
	
	var scale_filter := "scale=%d:%d" % [new_w, new_h]
	
	# --- GPU Path: single-pass constrained VBR (maxrate guarantees target size) ---
	if use_gpu and detected_gpu != GPU.NONE:
		var out_path: String = input_path.get_basename() + "_compressed.mp4"
		_run_ffmpeg(out_path, [
			"-c:v", get_hw_encoder(),
			"-b:v", str(int(v_kbps)) + "k",
			"-maxrate", str(int(v_kbps)) + "k",
			"-bufsize", str(int(v_kbps * 2)) + "k",
			"-vf", scale_filter,
			"-c:a", "aac", "-b:a", "128k"
		], input_path)
		return
	
	# --- CPU Path: classic 2-pass libx264 ---
	var log_file = input_path.get_basename() + "_2pass"
	
	# 1-й проход (без звука, только для анализа) — подавляем operation_done
	_suppress_op_done = true
	_run_ffmpeg("NUL", [
		"-c:v", "libx264", "-b:v", str(int(v_kbps)) + "k",
		"-vf", scale_filter,
		"-pass", "1", "-passlogfile", log_file,
		"-an", "-f", "mp4"
	], input_path)
	await ffmpeg_finished
	
	# 2-й проход (финальный, со звуком) — теперь operation_done сработает
	_suppress_op_done = false
	_run_ffmpeg(input_path.get_basename() + "_compressed.mp4", [
		"-c:v", "libx264", "-b:v", str(int(v_kbps)) + "k",
		"-vf", scale_filter,
		"-pass", "2", "-passlogfile", log_file,
		"-c:a", "aac", "-b:a", "128k"
	], input_path)
	await ffmpeg_finished
	
	# Очистка логов двухпроходного кодирования
	var _dir = DirAccess.open("user://")
	if _dir:
		_dir.remove(log_file + "-0.log")
		_dir.remove(log_file + "-0.log.mbtree")

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
	
	var ratio = current_size_mb / target_size_mb
	var estimated_q = clamp(int(ratio * 5.0), 2, 31) 
	
	var out_path = main.file_path.get_basename() + "_low.jpg"
	_run_ffmpeg(out_path, ["-q:v", str(estimated_q)])
	
# --- Utils ---
func get_video_resolution(path: String) -> Dictionary:
	# Returns DISPLAY resolution (accounts for rotation metadata).
	# Phone-recorded vertical videos often have coded 1920x1080 + rotation=90° → display 1080x1920.
	var output: Array[String] = []
	var code := OS.execute(ffprobe_path, [
		"-v", "error",
		"-select_streams", "v:0",
		"-show_entries", "stream",
		"-of", "json",
		path
	], output, true)
	if code == 0 and not output.is_empty():
		var json_str := ""
		for line in output:
			json_str += line
		var json: Variant = JSON.parse_string(json_str)
		if json != null and json is Dictionary and "streams" in json and json["streams"].size() > 0:
			var stream: Dictionary = json["streams"][0]
			var w: int = stream.get("width", 0)
			var h: int = stream.get("height", 0)
			# Rotation from tags (common for phone videos)
			var tags: Dictionary = stream.get("tags", {})
			var rotation: int = int(tags.get("rotate", "0"))
			# Rotation from side_data_list (Display Matrix, newer container format)
			if rotation == 0:
				var side_data_list: Array = stream.get("side_data_list", [])
				for sd: Variant in side_data_list:
					if sd is Dictionary and sd.get("side_data_type", "") == "Display Matrix":
						rotation = int(sd.get("rotation", 0))
						break
			# Swap for 90° / 270° rotation
			if rotation in [90, -90, 270, -270]:
				var tmp: int = w
				w = h
				h = tmp
			return {"width": w, "height": h}
	return {"width": 0, "height": 0}

func get_video_fps(path: String) -> float:
	var output: Array[String] = []
	var code := OS.execute(ffprobe_path, [
		"-v", "error",
		"-select_streams", "v:0",
		"-show_entries", "stream=r_frame_rate",
		"-of", "default=noprint_wrappers=1:nokey=1",
		path
	], output, true)
	if code == 0 and not output.is_empty():
		var parts := output[0].strip_edges().split("/")
		if parts.size() == 2:
			var num := parts[0].to_float()
			var den := parts[1].to_float()
			if den > 0:
				return num / den
		elif parts.size() == 1 and parts[0].to_float() > 0:
			return parts[0].to_float()
	return 30.0  # fallback

func get_duration_seconds(path: String) -> float:
	var output = []
	var code = OS.execute(ffprobe_path, ["-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", path], output, true)
	return output[0].strip_edges().to_float() if code == 0 and not output.is_empty() else 0.0

func format_time(seconds: float) -> String:
	return "%02d:%02d:%02d" % [int(seconds / 3600.0), int(fmod(seconds, 3600.0) / 60.0), int(fmod(seconds, 60.0))]
