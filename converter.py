import os
import sys
from kivy.app import App  # чтобы все писать не с нуля
from kivy.uix.boxlayout import BoxLayout  # единственный который я помню как работает
from kivy.uix.gridlayout import GridLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.uix.dropdown import DropDown
from kivy.core.window import Window
import subprocess
import json
from pathlib import Path

# class Main(App):  # все функции от App(встроенный плейсхолдер), будут в Main(наше приложение)
#     def build(self):
#         self.val = 0  # переменная, которая принадлежит классу, работает лучше, нужен self.
#         self.map = []  # это будет матрица, просто вспомогательная
#         self.label = Label(text='')
#         self.map.append([self.label])
#         self.butt = Button(text='Print', on_press=self.print)  # print() и self.print() - разное

#         # мне лень каждую кнопку вручную писать, но думаю суть ясна
#         for i in range(4):
#             self.map.append(
#                 [Button(text=f'+{j + i * 4}', on_press=self.func) for j in range(4)]
#             )
#         self.map[1][0].text = 'Clear'

#         self.map.append([self.butt])
#         self.layout = BoxLayout(orientation='vertical')
#         for row in self.map:
#             l = BoxLayout(orientation='horizontal')
#             for obj in row:
#                 l.add_widget(obj)
#             self.layout.add_widget(l)
#         return self.layout

#     def print(self, instance):  # instance - объект, который вызвал функцию, без него будет ошибка
#         self.label.text = str(self.val)

#     def func(self, instance: Button):
#         if instance.text == 'Clear':
#             self.val = 0
#             return
#         self.val += int(instance.text[1:])

#Color palette (0.0 - 1.0)




script_path = os.path.abspath(__file__)
script_abs_path = Path(os.path.abspath(__file__))
ffmpeg_folder = r"ffmpeg\bin\ffmpeg.exe"
ffprobe_folder = r"ffmpeg\bin\ffprobe.exe"
ffmpeg_path= script_path.replace("converter.py","")+ffmpeg_folder
ffprobe_path= script_path.replace("converter.py","")+ffprobe_folder

dev_mode=0
if dev_mode == 1:
    file = "D:\Клипы\clip.png"
else:
    file = str(sys.argv[1])
abs_file = Path(file)
file_types = {
    'image': ("jpg", "jpeg", "png", "bmp", "gif", "webp"),
    'video': ("mp4", "avi", "mov", "mkv", "webm", "flv", "wmv"),
    'audio': ("mp3", "wav", "flac", "aac", "ogg", "m4a")
}

with open(f"{script_abs_path.parent}\palletes.json", 'r+') as f:
    data = json.load(f)

last_used = data['last_used']
mainpallete = data['palletes'][last_used]  # получаешь последнюю палитру

buttons_design = {
    'background_color': mainpallete["Main"],
    'background_normal': 'misc/btn.png',
    'color': mainpallete["Highlight"],
    # 'border_width': 3,
    # 'outline_color': (1,1,1,1)
} #НАААЙС РАБОТАЕТ <<< а хули оно работаект то как новые добавить? ало ало хуем по лбу не дало??????????????????? ????<<<?????? я сделал
label_design = {
    'color': mainpallete["Contrast"],
    'font_name': "misc\InterTight-SemiBold.ttf",
    'font_size':13
}
edit_box_design = {
    'multiline': False,
    'background_color': mainpallete["Back"], 
    'foreground_color': mainpallete["Contrast"],
    'font_name': "misc/InterTight-Medium.ttf"
}

Window.clearcolor = mainpallete["Background"]




class WRecode(App):
    def build(self):
        self.map = []
         # я щас прийду
        file_layout = BoxLayout(orientation='horizontal')
        input_layout = BoxLayout(orientation='vertical')
        input_label = Label(text=f'Input file:', font_name="misc\InterTight-MediumItalic.ttf", font_size=22, color=mainpallete["Contrast"])
        # with input_label.canvas:
        #     Color(0, 1, 0, 0.25)
        #     Rectangle(pos=input_label.pos, size=input_label.size)

        # def change_file_path(self, instance):
        #     abs_file = Path(self.input.text)

        input_layout.add_widget(input_label)
        self.input = Label(text=file, font_name="misc\InterTight-SemiBold.ttf", font_size=18) # пиши в лс я без звука щаSyntaxError: positional argument follows keyword argument где ну я выделяю блят, ты
        input_layout.add_widget(self.input)
        file_layout.add_widget(input_layout)
        self.map.append([file_layout])

        choices = []

        # if " " in file:
        #     self.parameters = []
        #     choices = [Label(text='Try renaming the file so that the name\ndoes not contain spaces or special symbols', font_name="misc\InterTight-SemiBold.ttf", font_size=17)]
        #     labels = [Label(text='')]
            
        if file.split('.')[-1] in file_types['image']:
            self.parameters = [TextInput(**edit_box_design) for _ in range(3)]
            choices = [
                Button(text='Convert', on_press=lambda *args: self.convert_image(self, 0), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design),
                Button(text='Resize', on_press=lambda *args: self.resize_image(self, 1), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design),
                Button(text='Compress', on_press=lambda *args: self.compress_image(self, 2), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design)
                # Button(text='Compress with size', on_press=self.compress, size_hint = (2,1))
            ]
            labels = [
                Label(text=f'Write this formats(without .):\n {" ".join(file_types["image"])}', **label_design),
                Label(text='Write size e.g."1000:1000"', **label_design),
                Label(text='JPEG Compression (1-100)', **label_design)
            ]
        elif file.split('.')[-1] in file_types['video']:
            self.parameters = [TextInput(**edit_box_design) for _ in range(6)]
            choices = [
                Button(text='Convert', on_press=lambda *args: self.convert_video(self, 0), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design), # FFFF 424242 4242424242244242424242424242424242424242424242424242 оставляем похуй
                Button(text='Compress', on_press=lambda *args: self.compress_video_by_size(self, 1), size_hint=(2, 1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design),
                Button(text='Change FPS', on_press=lambda *args: self.change_fps(self, 2), size_hint=(2, 1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design),
                Button(text='Resize', on_press=lambda *args: self.resize_video(self, 3), size_hint=(2, 1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design),
                Button(text='Change bitrate', on_press=lambda *args: self.change_bitrate(self, 4), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design),
                Button(text='Change audiotrack bitrate', on_press=lambda *args: self.change_audio_bitrate_in_video(self, 5), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=30, **buttons_design),
                Button(text='Extract audio', on_press=self.extract_audio, size_hint=(3,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design)
            ]
            labels = [
                Label(text=f'Write this formats(without .):\n {" ".join(file_types["video"])}', **label_design),
                Label(text='Just write size in MB', **label_design),
                Label(text='Write FPS', **label_design),
                Label(text='Write size\n e.g."1000:1000"', **label_design),
                Label(text='Write bitrate\n in kb/s (only value)', **label_design),
                Label(text='Write bitrate\n in kb/s (only value)', **label_design),
                Label(text='Extract audiotrack\n from video', **label_design)
            ]
        elif file.split('.')[-1] in file_types['audio']:
            self.parameters = [TextInput(**edit_box_design) for _ in range(3)]
            choices = [
                Button(text='Convert', on_press=lambda *args: self.convert_audio(self, 0), size_hint = (2, 1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design),
                Button(text='Change bitrate', on_press=lambda *args: self.change_audio_bitrate(self, 1), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design),
                Button(text='Change sampling frequency', on_press=lambda *args: self.change_audio_samplerate(self, 2), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=30, **buttons_design) 
                # Button(text='Compress with size', on_press=self.com, size_hint = (2,1))
            ]
            labels = [
                Label(text=f'Write this formats(without .):\n {" ".join(file_types["audio"])}', **label_design),
                Label(text='Write bitrate in kb/s (only value)', **label_design),
                Label(text='Write sample rate', **label_design)
            ]
        else:
            self.parameters = []
            choices = [Label(text='File not supported', font_name="misc\InterTight-SemiBold.ttf", font_size=17)]
            labels = [Label(text='')]

        # for i in labels:
        #     with i.canvas:
        #         Color(0, 1, 0, 0.25)
        #         Rectangle(pos=i.pos, size=i.size)

        dropdown = DropDown()


        for i in range(len(self.parameters)):
            g = BoxLayout(orientation='horizontal')
            g.add_widget(choices[i])
            g.add_widget(self.parameters[i])
            g.add_widget(labels[i])
            self.map.append([g])
        for i in range(len(choices) - len(self.parameters)):
            g = BoxLayout(orientation='horizontal')
            g.add_widget(choices[i + len(self.parameters)])
            g.add_widget(labels[i + len(self.parameters)])
            self.map.append([g])
        self.layout = BoxLayout(orientation='vertical')
        
        # self.opened = None
        # self.settings = [
        #     Button(text='Themes', on_press=self.open_themes)
        # ]
        # self.themes = GridLayout()
        # self.themes.add_widget(Button(text='Dark', on_press=lambda *args: , color=pallete_dark['Main']))
        # self.themes.add_widget(Button(text='Dark Green', on_press=lambda *args: , color=pallete_darkgreen['Main']))
        # self.themes.add_widget(Button(text='White', on_press=lambda *args: , color=pallete_white['Main']))
        # self.themes.add_widget(Button(text='White Blue', on_press=lambda *args: , color=pallete_whiteblue['Main']))
        # self.themes.add_widget(Button(text='Default', on_press=lambda *args: , color=pallete_green['Main']))
        # self.themes.add_widget(Button(text='Pink', on_press=lambda *args: , color=pallete_pink['Main']))

        for row in self.map:
            l = BoxLayout(orientation='horizontal')
            for obj in row:
                l.add_widget(obj)
            self.layout.add_widget(l)
        
        self.window_size = (800, len(choices) * 75)
        
        self.settings_height = 0



        return self.layout
    

    # Сохранение новой палитры:
    # data['last_used'] = 'pallete_pink'  # меняешь на ту что выбрал

    # with open('palletes.json', 'w') as f:
    #     json.dump(data, f, indent=2)

    # def open_settings(self, instance):
    #     yiff: 
    #     return 

    def _print(self, instance):
        print(self.input.text)

    
    #Video funcs
    def change_audio_bitrate_in_video(self, instance, bitrate):
        command = [ffmpeg_path, '-i', file, '-b:a' ,f'{self.parameters[bitrate].text}k', f'{abs_file.stem}_audio_compressed_{self.parameters[bitrate].text}{abs_file.suffix}']
        subprocess.run(command, capture_output=True, text=True)

    def change_fps(self, instance, fps):
        command = [ffmpeg_path, '-i', file, '-vf', f'fps={self.parameters[fps].text}', f'{abs_file.stem}_editfps{self.parameters[fps].text}{abs_file.suffix}']
        subprocess.run(command, capture_output=True, text=True)

    def extract_audio(self, instance):
        command = [ffmpeg_path, '-i', file, '-vn', f'{abs_file.stem}_extracted.mp3']
        subprocess.run(command, capture_output=True, text=True)

    def change_bitrate(self, instance, bitrate):
        command = [ffmpeg_path, '-i', file, '-b:v' f'{self.parameters[bitrate].text}k', f'{abs_file.stem}_changed_bitrate{self.parameters[bitrate].text}{abs_file.suffix}']
        subprocess.run(command, capture_output=True, text=True)

    def convert_video(self, instance, format):
        command = [ffmpeg_path, '-i', abs_file.name, '-c copy' f'{abs_file.stem}.{self.parameters[format].text}']
        subprocess.run(command, capture_output=True, text=True)

    def compress_video_by_size(self, instance, target_size_mb):
        try:
            target_size_mb = float(self.parameters[target_size_mb].text)
            print("Please wait, calculating bitrate...")
            if target_size_mb <= 0:
                raise ValueError
        except:
            print("Invalid target size")
            return
        
        # ffprobe
        cmd = [
            ffprobe_path, "-v","error",
            "-print_format", "json",
            "-show_format",
            "-show_streams",
            file
        ]

        probe = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        if probe.returncode != 0:
            raise ValueError(f"ffprobe error: {probe.stderr}")

        data = json.loads(probe.stdout)

        duration = float(data["format"]["duration"])
        if duration <= 0:
            raise ValueError("Duration must be more than 0")

        audio_bitrate = 128000
        width = height = None

        for stream in data["streams"]:
            if stream.get("codec_type") == "audio" and "bit_rate" in stream:
                audio_bitrate = int(stream["bit_rate"])
                break

        for stream in data["streams"]:
            if stream.get("codec_type") == "video":
                width = int(stream.get("width", 0))
                height = int(stream.get("height", 0))
                break

        target_bits = target_size_mb *8*1024*1024
        total_bitrate = target_bits / duration
        audio_steps = [192000, 160000, 128000, 96000, 64000, 48000, 32000]
        audio_steps = [a for a in audio_steps if a <= audio_bitrate]
        if not audio_steps:
            audio_steps = [audio_bitrate]

        for a in audio_steps:
            vb = total_bitrate - a
            if vb >= 20000:
                audio_bitrate = a
                video_bitrate = vb
                break
        else:
            audio_bitrate = audio_steps[-1]
            video_bitrate = max(1, total_bitrate - audio_bitrate)


        if video_bitrate <= 0:
            raise ValueError("Size too small")

        video_kbps = int(video_bitrate/1000)
        audio_kbps = int(audio_bitrate/1000)

        dir_name = abs_file.parent
        base_name = abs_file.stem
        ext = abs_file.suffix
        # output_file = str(dir_name / f"{base_name}_compressed{ext}")
        passlog = dir_name / base_name

        if os.path.exists("ffmpeg2pass-0.log"):
            os.remove("ffmpeg2pass-0.log")

        null_out = "NUL" if os.name == "nt" else "/dev/null"
        print("The compression has began")
        pass1 = [ffmpeg_path, '-fflags', '+genpts+igndts', '-avoid_negative_ts', 'make_zero', '-loglevel info', '-i', file, '-fps_mode', 'passthrough', '-c:v', 'libx264', '-b:v', f'{video_kbps}k', '-pass', 1, '-passlogfile', passlog, '-an', '-f', 'null', null_out]
        pass2 = [ffmpeg_path, '-fflags', '+genpts+igndts', '-avoid_negative_ts', 'make_zero', '-loglevel info', '-i', file, '-fps_mode', 'passthrough', '-c:v', 'libx264', '-b:v', f'{video_kbps}k', '-pass', 2, '-passlogfile', passlog, '-c:a', 'aac', '-b:a', f'{audio_kbps}k', f'{abs_file.stem}_compessed{abs_file.suffix}']
        subprocess.run(pass1, capture_output=True, text=True)
        subprocess.run(pass2, capture_output=True, text=True)

        for ext in (".log", ".log.mbtree"):
            log_file = Path(str(passlog) + "-0" + ext)
            if log_file.exists():
                log_file.unlink()

    def resize_video(self, instance, size):
        command = [ffmpeg_path, '-i', file, '-vf', f'scale={self.parameters[size].text}', f'{abs_file.stem}_resized{self.parameters[size].text}{abs_file.suffix}']
        subprocess.run(command, capture_output=True, text=True)

    #Image funcs
    def convert_image(self, instance, format):
        command = [ffmpeg_path, '-i', file, f'{abs_file.stem}.{self.parameters[format].text}']
        subprocess.run(command, capture_output=True, text=True)

    def resize_image(self, instance, size):
        command = [ffmpeg_path, '-i', file, '-s', f'{self.parameters[size].text}', f'{abs_file.stem}_resized{self.parameters[size].text}{abs_file.suffix}']
        subprocess.run(command, capture_output=True, text=True)

    def compress_image(self, instance, jpeg_parameter):
        command = [ffmpeg_path, '-i', file, '-q:v', f'{self.parameters[jpeg_parameter].text}', f'{abs_file.stem}_compressed.jpg']
        subprocess.run(command, capture_output=True, text=True)
    #Audio funcs
    def convert_audio(self, instance, format):
        print(self.parameters[format].text)
        if self.parameters[format].text == "wav":
            command = [ffmpeg_path, '-i', file, '-c:a', 'pcm_s16le', f'{abs_file.stem}.{self.parameters[format].text}'] #Несжатый, высокое
        elif self.parameters[format].text == "mp3":
            command = [ffmpeg_path, '-i', file, '-c:a', 'libmp3lame', f'{abs_file.stem}.{self.parameters[format].text}']
        elif self.parameters[format].text == "flac":
            command = [ffmpeg_path, '-i', file, '-c:a', 'flac', '-compression_level', 8, f'{abs_file.stem}.{self.parameters[format].text}']
        elif self.parameters[format].text == "ogg":
            command = [ffmpeg_path, '-i', file, '-c:a', 'libvorbis', f'{abs_file.stem}.{self.parameters[format].text}']
        elif self.parameters[format].text == "aac":
            command = [ffmpeg_path, '-i', file, '-c:a', 'aac', f'{abs_file.stem}.{self.parameters[format].text}']
        elif self.parameters[format].text == "opus":
            command = [ffmpeg_path, '-i', file, '-c:a', 'libopus', f'{abs_file.stem}.{self.parameters[format].text}']
        elif self.parameters[format].text == "wma":
            command = [ffmpeg_path, '-i', file, '-c:a', 'wmav2', f'{abs_file.stem}.{self.parameters[format].text}']
        elif self.parameters[format].text == "aiff":
            command = [ffmpeg_path, '-i', file, '-c:a', 'pcm_s16be', f'{abs_file.stem}.{self.parameters[format].text}']
        else:
            command = "echo Wrong format"
        subprocess.run(command, capture_output=True, text=True)
    def change_audio_bitrate(self, instance, bitrate):
        command = [ffmpeg_path, '-i', file, '-c:a', 'libmp3lame', '-b:a', f'{self.parameters[bitrate].text}k', f'{abs_file.stem}_compressed{self.parameters[bitrate].text}.mp3']
        subprocess.run(command, capture_output=True, text=True)
    def change_audio_samplerate(self, instance, sample_rate):
        command = [ffmpeg_path, '-i', file, '-ar', f'{self.parameters[sample_rate].text}', f'{abs_file.stem}_{self.parameters[sample_rate].text}.wav']
        subprocess.run(command, capture_output=True, text=True)

WRecode().run()


# Имя с расширением: {p.name}   clip.mp4
# Имя без расширения: {p.stem}  clip
# Расширение файла: {p.suffix}  .mp4
# Родительская папка: {p.parent} D:\Клипы