extends Node
@export var devmode : bool
@onready var main: Control = $".."
var exe_dir : String
var ffmpeg_path : String
var ffprobe_path : String
var ffmpeg_pid : int = -1
var ffmpeg_stdout: FileAccess
var total_duration : float = 0.0
#ffmpeg stdout
var progress : float = 0.0
var fps: float = 0.0
var speed:float=0.0
var bitrate:String="0"
var current_time:float = 0.0
var eta : float =0.0
var formated_eta : String = "00:00:00"


signal ffmpeg_started
signal ffmpeg_finished
func _ready() -> void:
	if devmode:
		exe_dir = "E:/Godot/Projects/WRecode/"
	else:
		exe_dir = OS.get_executable_path().get_base_dir()
	print("exe_dir: ",exe_dir)
	ffmpeg_path = str(exe_dir+"/ffmpeg/bin/ffmpeg.exe")
	ffprobe_path = str(exe_dir+"/ffmpeg/bin/ffprobe.exe")
	if FileAccess.file_exists(ffmpeg_path) and FileAccess.file_exists(ffprobe_path):
		print("ffmpeg: ",ffmpeg_path)
		print("ffprobe: ",ffprobe_path)
	else:
		print(exe_dir)
		print(ffmpeg_path)
		push_error("ffmpeg not found")
		return
		



func _process(_delta) -> void:
	if ffmpeg_pid == -1:
		return
	read_ffmpeg_output()
	if not OS.is_process_running(ffmpeg_pid):
		print("FFmpeg finished")
		ffmpeg_pid = -1
		ffmpeg_finished.emit()
		return

func read_ffmpeg_output() -> void:
	if ffmpeg_stdout == null:
		return
	while not ffmpeg_stdout.eof_reached():
		var line: String = ffmpeg_stdout.get_line()
		if line == "":
			break
		parse_progress(line)

func parse_progress(line: String) -> void:
	if line.begins_with("fps="):
		fps = line.get_slice("=",1).to_float()
	elif line.begins_with("speed="):
		var s: String = line.get_slice("=",1).strip_edges()
		s = s.replace("x", "")
		speed = s.to_float()
	elif line.begins_with("bitrate="):
		bitrate = line.get_slice("=",1).strip_edges()
	elif line.begins_with("out_time_ms="):
		var ms_str: String = line.get_slice("=", 1)
		var ms: float = ms_str.to_float()

		current_time = ms / 1_000_000.0
		var est_progress: float = clamp(current_time / total_duration, 0.0, 1.0)
		progress = est_progress * 100.0
		
		if speed > 0.0:
			eta = (total_duration - current_time) / speed
			formated_eta = format_time(eta)
			
func format_time(seconds: float) -> String:
	if seconds <= 0.0:
		return "00:00:00"
		
	var total: int = int(seconds)
	
	var h: int = total / 3600
	var m: int = (total % 3600) / 60
	var s: int = total % 60
	
	return "%02d:%02d:%02d" % [h,m,s]

#region Video functions
func change_audio_bitrate_in_video(bitratee: String):
	ffmpeg_started.emit()
	total_duration = get_duration_seconds(main.file_path)
	if total_duration <= 0.0:
		push_error("Invalid duration")
		return
	if not FileAccess.file_exists(main.file_path):
		push_error("FILE NOT EXISTS")
		return
	if not FileAccess.file_exists(ffmpeg_path):
		push_error("FILE NOT EXISTS")
		return
		
	var command = ['-progress','pipe:1',"-i",main.file_path,"-b:a",bitratee+"k",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"_audio_compressed"+bitratee+"k "+"."+main.file_path.get_extension()]
	var exit_code: Dictionary = OS.execute_with_pipe(ffmpeg_path,command,false)
	
	set_stdout(exit_code)

func change_fps(fpss : String):
	ffmpeg_started.emit()
	total_duration = get_duration_seconds(main.file_path)
	if total_duration <= 0.0:
		push_error("Invalid duration")
		return
	if not FileAccess.file_exists(main.file_path):
		push_error("FILE NOT EXISTS")
		return
	if not FileAccess.file_exists(ffmpeg_path):
		push_error("FILE NOT EXISTS")
		return
	var command = ["-i",main.file_path,"-vf","fps="+fpss,main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"_"+fpss+"fps"+"."+main.file_path.get_extension()]
	var exit_code: Dictionary = OS.execute_with_pipe(ffmpeg_path,command,false)
	
	set_stdout(exit_code)

func extract_audio():
	ffmpeg_started.emit()
	total_duration = get_duration_seconds(main.file_path)
	if total_duration <= 0.0:
		push_error("Invalid duration")
		return
	if not FileAccess.file_exists(main.file_path):
		push_error("FILE NOT EXISTS")
		return
	if not FileAccess.file_exists(ffmpeg_path):
		push_error("FILE NOT EXISTS")
		return
		
	var command = ["-i",main.file_path,"-vn",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"_extracted.mp3"]
	var exit_code: Dictionary = OS.execute_with_pipe(ffmpeg_path,command,false)
	
	set_stdout(exit_code)

func change_bitrate(bitratee:String):
	ffmpeg_started.emit()
	total_duration = get_duration_seconds(main.file_path)
	if total_duration <= 0.0:
		push_error("Invalid duration")
		return
	if not FileAccess.file_exists(main.file_path):
		push_error("FILE NOT EXISTS")
		return
	if not FileAccess.file_exists(ffmpeg_path):
		push_error("FILE NOT EXISTS")
		return
		
	var command = ["-i",main.file_path,"-b:v",bitratee+"k",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"_"+bitratee+"."+main.file_path.get_extension()]
	var exit_code: Dictionary = OS.execute_with_pipe(ffmpeg_path,command,false)
	
	set_stdout(exit_code)
		
func convert_video(format:String):
	ffmpeg_started.emit()
	total_duration = get_duration_seconds(main.file_path)
	if total_duration <= 0.0:
		push_error("Invalid duration")
		return
	if not FileAccess.file_exists(main.file_path):
		push_error("FILE NOT EXISTS")
		return
	if not FileAccess.file_exists(ffmpeg_path):
		push_error("FILE NOT EXISTS")
		return
	var command = ["-i",main.file_path,"-c","copy",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
	print("COMMAND: ",command)
	var exit_code: Dictionary = OS.execute_with_pipe(ffmpeg_path,command,false)
	
	set_stdout(exit_code)
		
func compress_video_by_size(input_path: String, target_size_mb: float) -> void:
	print("Calculating bitrate...")
	
	# FFPROBE
	var probe_args = [
		"-v", "error",
		"-print_format", "json",
		"-show_format",
		"-show_streams",
		input_path
	]

	var output: Array = []
	var exit_code = OS.execute("ffprobe", probe_args, output, true)

	if exit_code != 0:
		print("ffprobe error")
		return

	var json_text: String = ""
	for line in output:
		json_text += line

	var data = JSON.parse_string(json_text)
	if data == null:
		print("Invalid ffprobe JSON")
		return

	var duration: float = float(data["format"]["duration"])
	if duration <= 0.0:
		print("Invalid duration")
		return

	# -----------------------
	# AUDIO BITRATE
	# -----------------------

	var audio_bitrate: int = 128000

	for stream in data["streams"]:
		if stream.get("codec_type", "") == "audio":
			if stream.has("bit_rate"):
				audio_bitrate = int(stream["bit_rate"])
			break

	# -----------------------
	# TARGET CALCULATION
	# -----------------------

	var target_bits = target_size_mb * 8.0 * 1024.0 * 1024.0
	var total_bitrate = target_bits / duration

	var audio_steps = [192000,160000,128000,96000,64000,48000,32000]
	var valid_steps: Array = []

	for a in audio_steps:
		if a <= audio_bitrate:
			valid_steps.append(a)

	if valid_steps.is_empty():
		valid_steps.append(audio_bitrate)

	var video_bitrate: float = 0.0

	for a in valid_steps:
		var vb = total_bitrate - a
		if vb >= 20000:
			audio_bitrate = a
			video_bitrate = vb
			break

	if video_bitrate <= 0.0:
		video_bitrate = max(1.0, total_bitrate - audio_bitrate)

	if video_bitrate <= 0:
		print("Size too small")
		return

	var video_kbps: int = int(video_bitrate / 1000.0)
	var audio_kbps: int = int(audio_bitrate / 1000.0)

	print("Video:", video_kbps, "kbps | Audio:", audio_kbps, "kbps")

	# -----------------------
	# PATHS
	# -----------------------

	var dir = input_path.get_base_dir()
	var base = input_path.get_file().get_basename()
	var ext = "." + input_path.get_extension()

	var passlog = dir + "/" + base
	var output_file = dir + "/" + base + "_compressed" + ext

	# удалить старые логи
	_delete_pass_logs(passlog)

	print("Compression started")

	# -----------------------
	# PASS 1
	# -----------------------

	run_ffmpeg_with_progress(input_path,
	output_file,
	["-fflags","+genpts+igndts",
	"-avoid_negative_ts","make_zero",
	"-c:v","libx264","-b:v",
	 str(video_kbps) + "k",
	"-pass","1","-passlogfile",
	 passlog,"-an","-f","null"])

	await _wait_ffmpeg_finish()

	# -----------------------
	# PASS 2
	# -----------------------

	run_ffmpeg_with_progress(
		input_path,
		output_file,
		[
			"-fflags","+genpts+igndts",
			"-avoid_negative_ts","make_zero",
			"-c:v","libx264",
			"-b:v", str(video_kbps) + "k",
			"-pass","2",
			"-passlogfile", passlog,
			"-c:a","aac",
			"-b:a", str(audio_kbps) + "k"
		]
	)

	await _wait_ffmpeg_finish()

	_delete_pass_logs(passlog)

	print("Done")

func resize_video(x:String,y:String):
	ffmpeg_started.emit()
	total_duration = get_duration_seconds(main.file_path)
	if total_duration <= 0.0:
		push_error("Invalid duration")
		return
	if not FileAccess.file_exists(main.file_path):
		push_error("FILE NOT EXISTS")
		return
	if not FileAccess.file_exists(ffmpeg_path):
		push_error("FILE NOT EXISTS")
		return
	var command = ["-i",main.file_path,"-vf","scale="+x+":"+y,main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"_"+x+"x"+y+"."+main.file_path.get_extension()]
	var exit_code: Dictionary = OS.execute_with_pipe(ffmpeg_path,command,false)
	
	set_stdout(exit_code)
#endregion

#region Image functions
func convert_image(format:String):
	ffmpeg_started.emit()
	if not FileAccess.file_exists(main.file_path):
		push_error("FILE NOT EXISTS")
		return
	if not FileAccess.file_exists(ffmpeg_path):
		push_error("FILE NOT EXISTS")
		return
	var command = ["-i",main.file_path,main.file_path.get_file().get_basename()+"."+format]
	OS.execute_with_pipe(ffmpeg_path,command,false)
	

func resize_image(x:String,y:String):
	ffmpeg_started.emit()
	if not FileAccess.file_exists(main.file_path):
		push_error("FILE NOT EXISTS")
		return
	if not FileAccess.file_exists(ffmpeg_path):
		push_error("FILE NOT EXISTS")
		return
	var command = ["-i",main.file_path,"-s",x+":"+y,main.file_path.get_file().get_basename()+"_"+x+":"+y+"."+main.file_path.get_extension()]
	OS.execute_with_pipe(ffmpeg_path,command,false)

func compress_image(jpeg_quality:String,compression_level : String):
	ffmpeg_started.emit()
	if not FileAccess.file_exists(main.file_path):
		push_error("FILE NOT EXISTS")
		return
	if not FileAccess.file_exists(ffmpeg_path):
		push_error("FILE NOT EXISTS")
		return
	var command = ["-i",main.file_path,"-q:v",jpeg_quality,"-compression_level",compression_level,"-huffman","default","-vf", "format=yuvj420p",main.file_path.get_file().get_basename()+".jpg"]
	OS.execute_with_pipe(ffmpeg_path,command,false)

#endregion

#region Audio funcs
func convert_audio(format):
	
	if format == "wav":
#Несжатый, высокое
		var command = ["-i",main.file_path,"-c:a","pcm_s16le",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		OS.execute_with_pipe(ffmpeg_path,command,false)
	elif format == "mp3":
#Универсальный
		var command = ["-i",main.file_path,"-c:a","libmp3lame",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		OS.execute_with_pipe(ffmpeg_path,command,false)

	elif format == "flac":
# Lossless
		var command = ["-i",main.file_path,"-c:a","flac",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		OS.execute_with_pipe(ffmpeg_path,command,false)
	elif format == "ogg":
		var command = ["-i",main.file_path,"-c:a","libvorbis",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		OS.execute_with_pipe(ffmpeg_path,command,false)
	elif format == "aac":
		var command = ["-i",main.file_path,"-c:a","aac",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		OS.execute_with_pipe(ffmpeg_path,command,false)
	elif format == "opus":
		var command = ["-i",main.file_path,"-c:a","libopus",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		OS.execute_with_pipe(ffmpeg_path,command,false)
	elif format == "wma":
		var command = ["-i",main.file_path,"-c:a","wmav2",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		OS.execute_with_pipe(ffmpeg_path,command,false)
	elif format == "aiff":
		var command = ["-i",main.file_path,"-c:a","pcm_s16be",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		OS.execute_with_pipe(ffmpeg_path,command,false)

func change_audio_bitrate(bitratee):
	var command = ["-i",main.file_path,"-c:a","libmp3lame","-b:a",bitratee+"k",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+bitrate+"k"+".mp3"]
	OS.execute_with_pipe(ffmpeg_path,command,false)
func change_audio_samplerate(sample_rate):
	var command = ["-i",main.file_path,"-ar",sample_rate,main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+sample_rate+".wav"]
	OS.execute_with_pipe(ffmpeg_path,command,false)

#endregion
func get_duration_seconds(path: String) -> float:
	var output: Array[String] = []
	var code: int = OS.execute(
		ffprobe_path,
		[
			"-v", "error",
			"-show_entries", "format=duration",
			"-of", "default=noprint_wrappers=1:nokey=1",
			path
		],
		output,
		true
	)

	if code != 0 or output.is_empty():
		push_error("ffprobe failed")
		return 0.0

	return output[0].strip_edges().to_float()

func set_stdout(exit_code):
	if not exit_code.has("pid"):
		push_error("FFmpeg failed to start")
		return
	
	ffmpeg_pid = exit_code.get("pid") as int
	ffmpeg_stdout = exit_code.get("stdio")
	
	if ffmpeg_stdout == null:
		push_error("stdout pipe is null")
		ffmpeg_pid = -1
		return

func run_ffmpeg_with_progress(input_path: String, output_path: String, extra_args: Array) -> void:
	var args: Array = []
	args.append("-i")
	args.append(input_path)

	for a in extra_args:
		args.append(a)

	args.append("-progress")
	args.append("pipe:1")

	args.append(output_path)

	OS.execute_with_pipe(ffmpeg_path, args, false)

func _wait_ffmpeg_finish() -> void:
	while OS.is_process_running(ffmpeg_pid):
		await get_tree().process_frame

func _delete_pass_logs(passlog: String) -> void:

	for ext in [".log", ".log.mbtree"]:
		var path = passlog + "-0" + ext
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
