extends Control

#var pallete_dark = {"Background": (18/255,17/255,19/255,1),
			#"Back": (34/255,29/255,37/255,1),
			#"Main": (137/255,152/255,120/255,1),
			#"Highlight": (228/255,230/255,195/255,1),
			#"Contrast": (247/255,247/255,242/255,1)}
#
#var pallete_darkblue = {"Background": (18/255,17/255,19/255,1),
			#"Back": (34/255,29/255,37/255,1),
			#"Main": (137/255,152/255,120/255,1),
			#"Highlight": (228/255,230/255,195/255,1),
			#"Contrast": (247/255,247/255,242/255,1)}
#
#var pallete_white = {"Background": (18/255,17/255,19/255,1),
			#"Back": (34/255,29/255,37/255,1),
			#"Main": (255/255,255/255,255/255,1),
			#"Highlight": (228/255,230/255,195/255,1),
			#"Contrast": (247/255,247/255,242/255,1)}
#
#var pallete_whiteblue = {"Background": (18/255,17/255,19/255,1),
			#"Back": (34/255,29/255,37/255,1),
			#"Main": (137/255,152/255,120/255,1),
			#"Highlight": (228/255,230/255,195/255,1),
			#"Contrast": (247/255,247/255,242/255,1)}
#
#var pallete_green = {"Background": (18/255,17/255,19/255,1),
			#"Back": (34/255,29/255,37/255,1),
			#"Main": (137/255,152/255,120/255,1),
			#"Highlight": (228/255,230/255,195/255,1),
			#"Contrast": (247/255,247/255,242/255,1)}
#
#var pallete_pink = {"Background": (96/255,36/255,55/255,1),
			#"Back": (138/255,40/255,70/255,1),
			#"Main": (224/255,122/255,162/255,1),
			#"Highlight": (225/255,194/255,212/255,1),
			#"Contrast": (225/255,224/255,233/255,1)}
var file_types = {
	'image': ["jpg", "jpeg", "png", "bmp", "gif", "webp"],
	'video': ["mp4", "avi", "mov", "mkv", "webm", "flv", "wmv"],
	'audio': ["mp3", "wav", "flac", "aac", "ogg", "m4a"]
}

var main_pallete
var main_font



#Video funcs
#func change_audio_bitrate_in_video(bitrate):
	#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -b:a {self.parameters[bitrate].text}k {abs_file.stem}_audio_compressed{abs_file.suffix}"
	#OS.system(command)
#
#func change_fps(fps):
	#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -r {self.parameters[fps].text} {abs_file.stem}_editfps{abs_file.suffix}"
	#os.system(command)
#
#func extract_audio():
	#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -vn {abs_file.stem}_extracted.mp3"
	#os.system(command)
#
#func change_bitrate(bitrate):
	#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -b:v {self.parameters[bitrate].text}k {abs_file.stem}_changed_bitrate{abs_file.suffix}"
	#os.system(command)
#
#func convert_video(format):
	#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -c copy {abs_file.stem}_converted.{self.parameters[format].text}"
	#os.system(command)
#
#func compress_video_by_size(size):
	#result = subprocess.run([f"{ffprobe_path}", "-v", "error", "-show_entries",
							#"format=duration", "-of",
							#"funcault=noprint_wrappers=1:nokey=1", file],
		#stdout=subprocess.PIPE,
		#stderr=subprocess.STDOUT)
	#duration = float(result.stdout)
#
	#filesize = os.path.getsize(file)/1024**2
#
	#new_bitrate = ((size * 8192) / duration)-128
	#print(duration)
	#print(filesize)
	#print(new_bitrate)
	#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -b:v {new_bitrate}k {abs_file.stem}_compressed{abs_file.suffix}"
	#os.system(command)
#
#func resize_video(size):
	#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -vf scale={self.parameters[size].text} {abs_file.stem}_resized{abs_file.suffix}"
	#os.system(command)
#
##Image funcs
#func convert_image(format):
	#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} {abs_file.stem}.{self.parameters[format].text}"
	#os.system(command)
#func resize_image(size):
	#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -s {self.parameters[size].text} {abs_file.stem}_resized{abs_file.suffix}"
	#os.system(command)
	#print(command)
#func compress_image(jpeg_parameter):
	#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -q:v {self.parameters[jpeg_parameter].text} {abs_file.stem}_compressed.jpg"
	#os.system(command)
##Audio funcs
#func convert_audio(format):
	#command = "echo empty"
	#if format == "wav":
		#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -c:a pcm_s16le {abs_file.name}.{format}" #Несжатый, высокое
	#if format == "mp3":
		#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -c:a libmp3lame {abs_file.name}.{format}" #Универсальный
	#if format == "flac":
		#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -c:a flac -compression_level 8 {abs_file.name}.{format}"# Lossless
	#if format == "ogg":
		#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -c:a libvorbis {abs_file.name}.{format}"
	#if format == "aac":
		#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -c:a aac {abs_file.name}.{format}"
	#if format == "opus":
		#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -c:a libopus {abs_file.name}.{format}"
	#if format == "wma":
		#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -c:a wmav2 {abs_file.name}.{format}"
	#if format == "aiff":
		#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -c:a pcm_s16be {abs_file.name}.{format}"
#
	#os.system(command)
#func change_audio_bitrate(bitrate):
	#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -c:a libmp3lame -b:a {self.parameters[bitrate].text}k {abs_file.stem}_compressed.mp3"
	#os.system(command)
#func change_audio_samplerate(sample_rate):
	#command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -ar {self.parameters[sample_rate].text} {abs_file.stem}_{self.parameters[sample_rate].text}.wav"
	#os.system(command)
