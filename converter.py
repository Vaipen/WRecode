import os
import ffmpeg
from kivy.app import App  # чтобы все писать не с нуля
from kivy.uix.boxlayout import BoxLayout  # единственный который я помню как работает
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.uix.dropdown import DropDown
from kivy.core.image import Image
from kivy.core.window import Window
from kivy.graphics.texture import Texture
from kivy.graphics import Color, Rectangle
import subprocess
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
cpallete = {"Black": (18/255,17/255,19/255,1),
            "Dark": (34/255,29/255,37/255,1),
            "Main": (137/255,152/255,120/255,1),
            "Highlight": (228/255,230/255,195/255,1),
            "White": (247/255,247/255,242/255,1)}




script_path = os.path.abspath(__file__)
ffmpeg_folder = r"ffmpeg\bin\ffmpeg.exe"
ffprobe_folder = r"ffmpeg\bin\ffprobe.exe"
ffmpeg_path= script_path.replace("converter.py","")+ffmpeg_folder
ffprobe_path= script_path.replace("converter.py","")+ffprobe_folder
file = r"D:\Клипы\НАПЕРДЫШ.mp4"
abs_file = Path(file)
file_types = {
    'image': ("jpg", "jpeg", "png", "bmp", "gif", "webp"),
    'video': ("mp4", "avi", "mov", "mkv", "webm", "flv", "wmv"),
    'audio': ("mp3", "wav", "flac", "aac", "ogg", "m4a")
}

buttons_design = {
    'background_color': cpallete["Main"], 
    'outline_color': cpallete["Highlight"],
    'color': cpallete["Highlight"]
    # 'border_width': 2,
    # 'outline_color': (1,1,1,1)
} #НАААЙС РАБОТАЕТ <<< а хули оно работаект тоак нвые длобавть? ало ало хуем по лбу не дало??????????????????? ????<<<?????? я сделал
label_design = {
    'color': cpallete["White"],
    # 'border_width': 2,
    # 'outline_color': (1,1,1,1)
}
edit_box_design = {
    'background_color': cpallete["Dark"], 
    'foreground_color': cpallete["White"],
    # 'outline_width': 2,
    # 'outline_color': (1,1,1,1)
}

Window.clearcolor = cpallete["Black"]

class WRecode(App):
    def build(self):
        self.map = []
         # я щас прийду
        file_layout = BoxLayout(orientation='horizontal')
        input_layout = BoxLayout(orientation='vertical')
        input_label = Label(text=f'Input file:', font_name="misc\InterTight-MediumItalic.ttf", font_size=22, **label_design)
        # with input_label.canvas:
        #     Color(0, 1, 0, 0.25)
        #     Rectangle(pos=input_label.pos, size=input_label.size)
        input_layout.add_widget(input_label)
        self.input = TextInput(text=file, **edit_box_design) # пиши в лс я без звука щаSyntaxError: positional argument follows keyword argument где ну я выделяю блят, ты 
        input_layout.add_widget(self.input)
        output_layout = BoxLayout(orientation='vertical')
        output_label = Label(text=f'Output file:', font_name="misc\InterTight-MediumItalic.ttf", font_size=22, **label_design)
        # with output_label.canvas:
        #     Color(0, 1, 0, 0.25)
        #     Rectangle(pos=output_label.pos, size=output_label.size)
        output_layout.add_widget(output_label)
        self.output = TextInput(text=os.path.dirname(file), **edit_box_design)
        output_layout.add_widget(self.output)
        file_layout.add_widget(input_layout)
        file_layout.add_widget(output_layout)
        self.map.append([file_layout])

        choices = []
        if file.split('.')[-1] in file_types['image']:
            self.parameters = [TextInput(**edit_box_design) for _ in range(3)]
            choices = [
                Button(text='Convert', on_press=lambda *args: self.convert_image(self, 0), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design),
                Button(text='Resize', on_press=lambda *args: self.resize_image(self, 1), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design),
                Button(text='Compress', on_press=lambda *args: self.compress_image(self, 2), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design)
                # Button(text='Compress with size', on_press=self.compress, size_hint = (2,1))
            ]
            labels = [
                Label(text=f'Write this formats(without .):\n {" ".join(file_types["image"])}', font_name="misc\InterTight-SemiBold.ttf", font_size=13),
                Label(text='Write size e.g."1000x1000"', font_name="misc\InterTight-SemiBold.ttf", font_size=13),
                Label(text='JPEG Compression (1-100)', font_name="misc\InterTight-SemiBold.ttf", font_size=13)
            ]
        elif file.split('.')[-1] in file_types['video']:
            self.parameters = [TextInput(**edit_box_design) for _ in range(6)]
            choices = [
                Button(text='Convert', on_press=lambda *args: self.convert_video(self, 0), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design, texture=Texture("misc\silly.jpg")), # FFFF 424242 4242424242244242424242424242424242424242424242424242 оставляем похуй
                Button(text='Change bitrate', on_press=lambda *args: self.change_bitrate(self, 1), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design),
                Button(text='Change audiotrack bitrate', on_press=lambda *args: self.change_audio_bitrate_in_video(self, 2), size_hint = (2,1), font_name="misc\InterTight-Bold.ttf", font_size=30, **buttons_design),
                Button(text='Compress by size', on_press=lambda *args: self.compress_video_by_size(self, 3), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design),
                Button(text='Change FPS', on_press=lambda *args: self.change_fps(self, 4), size_hint = (2,1), font_name="misc\InterTight-Bold.ttf", font_size=42, **buttons_design),
                Button(text='Resize', on_press=lambda *args: self.resize_video(self, 5), size_hint = (2,1), font_name="misc\InterTight-Bold.ttf", font_size=42, **buttons_design),
                Button(text='Extract audio', on_press=self.extract_audio, size_hint=(3,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design)
            ]
            labels = [
                Label(text=f'Write this formats(without .):\n {" ".join(file_types["video"])}', font_name="misc\InterTight-SemiBold.ttf", font_size=13),
                Label(text='Write bitrate\n in kb/s (only value)', font_name="misc\InterTight-SemiBold.ttf", font_size=13),
                Label(text='Write bitrate\n in kb/s (only value)', font_name="misc\InterTight-SemiBold.ttf", font_size=13),
                Label(text='Write size in MB \n working not properly', font_name="misc\InterTight-SemiBold.ttf", font_size=13),
                Label(text='Write FPS', font_name="misc\InterTight-SemiBold.ttf", font_size=13),
                Label(text='Write size\n e.g."1000:1000"', font_name="misc\InterTight-SemiBold.ttf", font_size=13),
                Label(text='Extract audiotrack\n from video', font_name="misc\InterTight-SemiBold.ttf", font_size=13)
            ]
        elif file.split('.')[-1] in file_types['audio']:
            self.parameters = [TextInput(**edit_box_design) for _ in range(2)]
            choices = [
                # Button(text='Convert', on_press=self.c, size_hint = (2,1)),
                Button(text='Change bitrate', on_press=lambda *args: self.change_audio_bitrate(self, 0), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=42, **buttons_design),
                Button(text='Change sampling frequency', on_press=lambda *args: self.change_audio_samplerate(self, 1), size_hint = (2,1), font_name="misc\InterTight-Black.ttf", font_size=30, **buttons_design) 
                # Button(text='Compress with size', on_press=self.com, size_hint = (2,1))
            ]
            labels = [
                Label(text='Write bitrate in kb/s (only value)', font_name="misc\InterTight-SemiBold.ttf", font_size=13),
                Label(text='Write sample rate', font_name="misc\InterTight-SemiBold.ttf", font_size=13)
            ]
        else:
            self.parameters = []

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
        
        for row in self.map:
            l = BoxLayout(orientation='horizontal')
            for obj in row:
                l.add_widget(obj)
            self.layout.add_widget(l)
        
        return self.layout

    def _print(self, instance):
        print(self.input.text)

    
    #Video funcs
    def change_audio_bitrate_in_video(self, instance, bitrate):
        command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -b:a {self.parameters[bitrate].text}k {abs_file.stem}_audio_compressed{abs_file.suffix}"
        os.system(command)

    def change_fps(self, instance, fps):
        command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -r {self.parameters[fps].text} {abs_file.stem}_editfps{abs_file.suffix}"
        os.system(command)

    def extract_audio(self, instance):
        command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -vn {abs_file.stem}_extracted.mp3"
        os.system(command)

    def change_bitrate(self, instance, bitrate):
        command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -b:v {self.parameters[bitrate].text}k {abs_file.stem}_changed_bitrate{abs_file.suffix}"
        os.system(command)

    def convert_video(self, instance, format):
        command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -c copy {abs_file.stem}_converted{self.parameters[format].text}"
        os.system(command)

    def compress_video_by_size(self, instance, size):
        result = subprocess.run([f"{ffprobe_path}", "-v", "error", "-show_entries",
                                "format=duration", "-of",
                                "default=noprint_wrappers=1:nokey=1", file],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT)
        duration = float(result.stdout)

        filesize = os.path.getsize(file)/1024**2

        new_bitrate = ((size * 8192) / duration)-128
        print(duration)
        print(filesize)
        print(new_bitrate)
        command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -b:v {new_bitrate}k {abs_file.stem}_compressed{abs_file.suffix}"
        os.system(command)

    def resize_video(self, instance, size):
        command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -vf scale={self.parameters[size].text} {abs_file.stem}_resized{abs_file.suffix}"
        os.system(command)

    #Image funcs
    def convert_image(self, instance, format):
        command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} {abs_file.stem}.{self.parameters[format].text}"
        os.system(command)
    def resize_image(self, instance, size):
        command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -s {self.parameters[size].text} {abs_file.stem}_resized{abs_file.suffix}"
        os.system(command)
    def compress_image(self, instance, jpeg_parameter):
        command = f"cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -q:v {self.parameters[jpeg_parameter].text} {abs_file.stem}_compressed.jpg"
        os.system(command)
    #Audio funcs
    # def convert_audio(self, instance, format):
    #     command = f"echo UMC && cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -s {size_x}x{size_y} {abs_file.name}_resized.{format}"
    #     os.system(command)
    def change_audio_bitrate(self, instance, bitrate):
        command = f"echo UMC && cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -c:a libmp3lame -b:a {self.parameters[bitrate].text}k {abs_file.stem}_compressed.mp3"
        os.system(command)
    def change_audio_samplerate(self, instance, sample_rate):
        command = f"echo UMC && cd /D {os.path.dirname(file)} && {ffmpeg_path} -i {abs_file.name} -c:a copy -ar {self.parameters[sample_rate].text} {abs_file.stem}_{self.parameters[sample_rate].text}.wav"
        os.system(command)
    


WRecode().run()


# Имя с расширением: {p.name}   clip.mp4
# Имя без расширения: {p.stem}  clip
# Расширение файла: {p.suffix}  .mp4
# Родительская папка: {p.parent} D:\Клипы