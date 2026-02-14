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

#
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
		print("SPEED:", s)
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
	var m: int = (total%3600) / 60
	var s: int = total % 60
	
	return "%02d:%02d:%02d" % [h,m,s]

#region Video functions
func change_audio_bitrate_in_video(bitrate: String):
	var command = ['-progress','pipe:1',"-i",main.file_path,"-b:a",bitrate+"k",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"_audio_compressed"+bitrate+"k "+"."+main.file_path.get_extension()]
	var output := []
	var exit_code = OS.execute(ffmpeg_path,command,output, true)
	if exit_code == 0:
		print("Output FFmpeg: ",output)
	else:
		print("Error: ",exit_code)

func change_fps(fps : String):
	var command = ["-i",main.file_path,"-vf","fps="+fps,main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"_"+fps+"fps"+"."+main.file_path.get_extension()]
	var output := []
	var exit_code = OS.execute(ffmpeg_path,command,output, true)
	if exit_code == 0:
		print("Output FFmpeg: ",output)
	else:
		print("Error: ",exit_code)

func extract_audio():
	var command = ["-i",main.file_path,"-vn",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"_extracted.mp3"]
	var output := []
	var exit_code = OS.execute(ffmpeg_path,command,output, true)
	if exit_code == 0:
		print("Output FFmpeg: ",output)
	else:
		print("Error: ",exit_code)

func change_bitrate(bitrate:String):
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
		
	var command = ['-progress','pipe:1',"-i",main.file_path,"-b:v",bitrate+"k",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"_"+bitrate+"."+main.file_path.get_extension()]
	var exit_code: Dictionary = OS.execute_with_pipe(ffmpeg_path,command,false)
	
	if not exit_code.has("pid"):
		push_error("FFmpeg failed to start")
		return
	
	ffmpeg_pid = exit_code.get("pid") as int
	ffmpeg_stdout = exit_code.get("stdio")
	
	if ffmpeg_stdout == null:
		push_error("stdout pipe is null")
		ffmpeg_pid = -1
		return
		
func convert_video(format:String):
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
	
	if not exit_code.has("pid"):
		push_error("FFmpeg failed to start")
		return
	
	ffmpeg_pid = exit_code.get("pid") as int
	ffmpeg_stdout = exit_code.get("stdio") as FileAccess
	
	if ffmpeg_stdout == null:
		push_error("stdout pipe is null")
		ffmpeg_pid = -1
		return
		
#func compress_video_by_size(self, instance, target_size_mb):
	#if " " in str(abs_file.name):
		#print("The file name contains spaces, please remove them.")
		#return
	#
	#try:
		#target_size_mb = float(self.parameters[target_size_mb].text)
		#print("Please wait, calculating bitrate...")
		#if target_size_mb <= 0:
			#raise ValueError
	#except:
		#print("Invalid target size")
		#return
	#
	## ffprobe
	#cmd = [
		#ffprobe_path, "-v","error",
		#"-print_format", "json",
		#"-show_format",
		#"-show_streams",
		#file
	#]
#
	#probe = subprocess.run(
		#cmd,
		#stdout=subprocess.PIPE,
		#stderr=subprocess.PIPE,
		#text=True
	#)
	#if probe.returncode != 0:
		#raise ValueError(f"ffprobe error: {probe.stderr}")
#
	#data = json.loads(probe.stdout)
#
	#duration = float(data["format"]["duration"])
	#if duration <= 0:
		#raise ValueError("Duration must be more than 0")
#
	#audio_bitrate = 128000
	#width = height = None
#
	#for stream in data["streams"]:
		#if stream.get("codec_type") == "audio" and "bit_rate" in stream:
			#audio_bitrate = int(stream["bit_rate"])
			#break
#
	#for stream in data["streams"]:
		#if stream.get("codec_type") == "video":
			#width = int(stream.get("width", 0))
			#height = int(stream.get("height", 0))
			#break
#
	#target_bits = target_size_mb *8*1024*1024
	#total_bitrate = target_bits / duration
	#audio_steps = [192000, 160000, 128000, 96000, 64000, 48000, 32000]
	#audio_steps = [a for a in audio_steps if a <= audio_bitrate]
	#if not audio_steps:
		#audio_steps = [audio_bitrate]
#
	#for a in audio_steps:
		#vb = total_bitrate - a
		#if vb >= 20000:
			#audio_bitrate = a
			#video_bitrate = vb
			#break
	#else:
		#audio_bitrate = audio_steps[-1]
		#video_bitrate = max(1, total_bitrate - audio_bitrate)
#
#
	#if video_bitrate <= 0:
		#raise ValueError("Size too small")
#
	#video_kbps = int(video_bitrate/1000)
	#audio_kbps = int(audio_bitrate/1000)
#
	#dir_name = abs_file.parent
	#base_name = abs_file.stem
	#ext = abs_file.suffix
	## output_file = str(dir_name / f"{base_name}_compressed{ext}")
	#passlog = dir_name / base_name
#
	#if os.path.exists("ffmpeg2pass-0.log"):
		#os.remove("ffmpeg2pass-0.log")
#
	#null_out = "NUL" if os.name == "nt" else "/dev/null"
	#print("The compression has began")
	#pass1 = (f'{ffmpeg_path} -fflags +genpts+igndts -avoid_negative_ts make_zero -loglevel info  -i "{file}" -fps_mode passthrough -c:v libx264 -b:v {video_kbps}k -pass 1 -passlogfile "{passlog}" -an -f null {null_out}')
	#pass2 = (f'{ffmpeg_path} -fflags +genpts+igndts -avoid_negative_ts make_zero -loglevel info  -i "{file}" -fps_mode passthrough -c:v libx264 -b:v {video_kbps}k -pass 2 -passlogfile "{passlog}" -c:a aac -b:a {audio_kbps}k {abs_file.stem}_compessed{abs_file.suffix}')
	#os.system(pass1)
	#os.system(pass2)
#
	#for ext in (".log", ".log.mbtree"):
		#log_file = Path(str(passlog) + "-0" + ext)
		#if log_file.exists():
			#log_file.unlink()

func resize_video(x:String,y:String):
	var command = ["-i",main.file_path,"-vf","scale="+x+":"+y,main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"_"+x+"x"+y+"."+main.file_path.get_extension()]
	var output := []
	var exit_code = OS.execute(ffmpeg_path,command,output, true)
	if exit_code == 0:
		print("Output FFmpeg: ",output)
	else:
		print("Error: ",exit_code)
#endregion

#region Image functions
func convert_image(format:String):
	var command = ["-i",main.file_path,main.file_path.get_file().get_basename()+"."+format]
	var output := []
	var exit_code = OS.execute(ffmpeg_path,command,output, true)
	if exit_code == 0:
		print("Output FFmpeg: ",output)
	else:
		print("Error: ",exit_code)

func resize_image(x:String,y:String):
	var command = ["-i",main.file_path,"-s",x+":"+y,main.file_path.get_file().get_basename()+"_"+x+":"+y+"."+main.file_path.get_extension()]
	var output := []
	var exit_code = OS.execute(ffmpeg_path,command,output, true)
	if exit_code == 0:
		print("Output FFmpeg: ",output)
	else:
		print("Error: ",exit_code)

func compress_image(jpeg_quality:String,compression_level : String):
	var command = ["-i",main.file_path,"-q:v",jpeg_quality,"-compression_level",compression_level,"-huffman","default","-vf", "format=yuvj420p",main.file_path.get_file().get_basename()+".jpg"]
	var output := []
	var exit_code = OS.execute(ffmpeg_path,command,output, true)
	if exit_code == 0:
		print("Output FFmpeg: ",output)
	else:
		print("Error: ",exit_code)
#endregion

#Audio funcs
func convert_audio(format):
	if format == "wav":
#Несжатый, высокое
		var command = ["-i",main.file_path,"-c:a","pcm_s16le",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		var output := []
		var exit_code = OS.execute(ffmpeg_path,command,output, true)
		if exit_code == 0:
			print("Output FFmpeg: ",output)
		else:
			print("Error: ",exit_code)
	elif format == "mp3":
#Универсальный
		var command = ["-i",main.file_path,"-c:a","libmp3lame",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		var output := []
		var exit_code = OS.execute(ffmpeg_path,command,output, true)
		if exit_code == 0:
			print("Output FFmpeg: ",output)
		else:
			print("Error: ",exit_code)
	elif format == "flac":
# Lossless
		var command = ["-i",main.file_path,"-c:a","flac",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		var output := []
		var exit_code = OS.execute(ffmpeg_path,command,output, true)
		if exit_code == 0:
			print("Output FFmpeg: ",output)
		else:
			print("Error: ",exit_code)
	elif format == "ogg":
		var command = ["-i",main.file_path,"-c:a","libvorbis",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		var output := []
		var exit_code = OS.execute(ffmpeg_path,command,output, true)
		if exit_code == 0:
			print("Output FFmpeg: ",output)
		else:
			print("Error: ",exit_code)
	elif format == "aac":
		var command = ["-i",main.file_path,"-c:a","aac",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		var output := []
		var exit_code = OS.execute(ffmpeg_path,command,output, true)
		if exit_code == 0:
			print("Output FFmpeg: ",output)
		else:
			print("Error: ",exit_code)
	elif format == "opus":
		var command = ["-i",main.file_path,"-c:a","libopus",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		var output := []
		var exit_code = OS.execute(ffmpeg_path,command,output, true)
		if exit_code == 0:
			print("Output FFmpeg: ",output)
		else:
			print("Error: ",exit_code)
	elif format == "wma":
		var command = ["-i",main.file_path,"-c:a","wmav2",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		var output := []
		var exit_code = OS.execute(ffmpeg_path,command,output, true)
		if exit_code == 0:
			print("Output FFmpeg: ",output)
		else:
			print("Error: ",exit_code)
	elif format == "aiff":
		var command = ["-i",main.file_path,"-c:a","pcm_s16be",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+"."+format]
		var output := []
		var exit_code = OS.execute(ffmpeg_path,command,output, true)
		if exit_code == 0:
			print("Output FFmpeg: ",output)
		else:
			print("Error: ",exit_code)

func change_audio_bitrate(bitrate):
	var command = ["-i",main.file_path,"-c:a","libmp3lame","-b:a",bitrate+"k",main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+bitrate+"k"+".mp3"]
	var output := []
	var exit_code = OS.execute(ffmpeg_path,command,output, true)
	if exit_code == 0:
		print("Output FFmpeg: ",output)
	else:
		print("Error: ",exit_code)
func change_audio_samplerate(sample_rate):
	var command = ["-i",main.file_path,"-ar",sample_rate,main.file_path.get_base_dir()+"/"+main.file_path.get_file().get_basename()+sample_rate+".wav"]
	var output := []
	var exit_code = OS.execute(ffmpeg_path,command,output, true)
	if exit_code == 0:
		print("Output FFmpeg: ",output)
	else:
		print("Error: ",exit_code)

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
