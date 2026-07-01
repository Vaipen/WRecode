# WRecode

<p align="center">
  <img width="2607" height="512" alt="Full" src="https://github.com/user-attachments/assets/331c5f1d-d5a2-4e7d-8223-124a639e4643" />
</p>

**A lean, mean FFMPEG GUI** — because typing `ffmpeg -i` in the terminal is so 2010.

WRecode wraps the raw power of FFMPEG into a clean, clickable interface. No config files, no command chains, no bullshit. Pick a file, pick what you want to do with it, and let the machine eat.

---

## 🚀 The Main Event — Batch Queue Processing

Wanna compress 12 video clips for a Discord group chat? **Select 'em all, right-click → Send To → WRecode** and boom — they get processed one by one with the exact same settings. No babysitting required.

A queue counter shows you which file is cooking ("File 3 of 12"), real-time progress with FPS, bitrate, and ETA, and a **sound** when the whole batch is done. Set it and forget it.

---

## 🎬 Video — Where WRecode Really Shines

### 🎯 Compress to Exact File Size
This is the killer feature. Type in **how many megabytes** you want the output to be, and WRecode figures out the rest — optimal resolution, bitrate, and runs **2-pass H.264 encoding** to squeeze every last bit of quality into that size limit.

No more guessing. No more "50 MB? Nope, 74." One number, done.

It works by analyzing your video's duration, resolution, and FPS, then calculating the **sweet-spot resolution** (800 pixels per kbps at 30fps baseline). Short clips keep high res. Long videos scale down gracefully. Math does the work.

### 📐 Resize — Exact Pixels or Quick Scale Factor
- `1280:720` — exact resolution
- `x2` — cut resolution in half  
- `x3` — one third the size  
- `x4` — quarter of the original

Handy when you need 1080p → 540p for a quick upload.

### 🔄 Convert Between Formats
MP4, AVI, MOV, MKV, FLV, WMV — pick one, get another. Stream copy mode keeps it fast when possible.

### ⏱ Change FPS
Need 60fps footage down to 30fps (or 24, or 12 for that crunchy stop-motion look)? Type it in.

### 🔊 Extract Audio
Rip the audio track out to MP3 in one click. No video editor needed.

### 🎛 Tweak Bitrates
- Change video bitrate — shrink or boost quality
- Change audio bitrate inside a video — keep video untouched, re-encode only the audio

---

## 🖼 Images

- **Convert:** JPG, PNG, BMP, GIF, WEBP — flip between formats
- **Compress:** Hit a target size with automatic quality tuning
- **Resize:** Scale down by exact dimensions (e.g. `1920:1080`)

---

## 🎵 Audio

- **Convert:** MP3, WAV, FLAC, AAC, OGG — swap codecs
- **Change bitrate:** Lower for smaller files, higher for quality
- **Change sample rate:** 44100, 48000, 96000 — whatever your project needs

---

## 📦 SendTo Integration

First launch walks you through installing a **Windows SendTo shortcut**. After that:

**Right-click any file → Send To → WRecode.bat**

That's it. The app opens with your file loaded, ready to go. Select multiple files and they all land in the batch queue automatically.

<p align="center">
  <img width="748" height="589" alt="Sendto" src="https://github.com/user-attachments/assets/ff8084e9-2f9a-4626-9265-77b5b3fbb13f" />
</p>

---

## ⚡ Tech Bits

- Built in **Godot 4.7**
- Ships with its own **FFMPEG & FFProbe** — no PATH configuration required
- Real-time progress bar
- Live stats: FPS, encoding speed, bitrate, ETA
- Windows 10/11 only (sorry, Linux enjoyers — the SendTo integration is pure Windows)

---

## ☕ Support

If this tool saves you time, buys you a coffee, or just makes you smile:

<p align="center">
  <a href="https://dalink.to/waipek">
    <img src="https://img.shields.io/badge/Support%20me-ff69b4?style=for-the-badge" alt="Support me" />
  </a>
</p>

---

# WRecode — Русская версия

<p align="center">
  <img width="2607" height="512" alt="Full" src="https://github.com/user-attachments/assets/331c5f1d-d5a2-4e7d-8223-124a639e4643" />
</p>

**Простая FFMPEG обёртка** для тех, кто не хочет дрочить терминал.

WRecode даёт тебе всю мощь FFMPEG в чистом, понятном интерфейсе. Никаких конфигов, никаких цепочек аргументов — выбрал файл, ткнул кнопку, и погнал.

---

## 🚀 Главная фишка — Очередь

Надо сжать 12 видосов для Discord? **Выдели их все → правой кнопкой → Отправить → WRecode** — и они обработаются один за другим с одними и теми же настройками.

Счётчик показывает "Файл 3 из 12", в реальном времени видно FPS, битрейт, ETA, а когда всё готово — **Windows-уведомление + звук**. Воткнул и забыл.

---

## 🎬 Видео — ради этого всё затевалось

### 🎯 Сжатие до конкретного размера
Вбиваешь **сколько мегабайт** нужно на выходе — WRecode сам подбирает оптимальное разрешение, битрейт и делает **2-проходной H.264 кодинг**, чтобы выжать максимум качества в этот лимит.

Никаких «ну, попробуй 50 мегов… а нет, 74 получилось». Одна цифра — готово.

Алгоритм смотрит на длину видео, разрешение и FPS, после чего считает **идеальное разрешение** (800 пикселей на 1 kbps при 30fps). Короткие ролики остаются чёткими. Длинные — плавно снижают разрешение.

### 📐 Изменить разрешение
- `1280:720` — точный размер
- `x2` — уменьшить в два раза
- `x3` — в три
- `x4` — в четыре

Затащить 1080p → 540p для быстрой заливки? Раз плюнуть.

### 🔄 Конвертация форматов
MP4, AVI, MOV, MKV, FLV, WMV — выбрал, конвертнул. Stream copy — максимальная скорость.

### ⏱ Изменить FPS
60fps → 30fps? 24? 12 для этого лампового стоп-моушен вайба? Просто введи число.

### 🔊 Извлечь аудио
Вытащить дорожку в MP3 в один клик. Без видео-редакторов и танцев с бубном.

### 🎛 Битрейты
- **Видео:** меняешь битрейт — жмёшь качество или размер
- **Аудио внутри видео:** перекодируется только звук, картинка летит без пережатия

---

## 🖼 Изображения

- **Конвертация:** JPG, PNG, BMP, GIF, WEBP — туда-сюда
- **Сжатие:** пишешь нужный размер — автоподбор качества
- **Ресайз:** уменьшить до точных пикселей

---

## 🎵 Аудио

- **Конвертация:** MP3, WAV, FLAC, AAC, OGG
- **Битрейт:** меньше → легче файл, больше → сочнее звук
- **Частота дискретизации:** 44100, 48000, 96000

---

## 📦 SendTo

При первом запуске устанавливается пункт в **контекстное меню «Отправить в»**. Всё.

**Правой кнопкой по файлу → Отправить в→ WRecode.bat**

Программа открывается с твоим файлом, готовым к обработке. Выбрал несколько — все попадают в очередь.

<p align="center">
  <img width="748" height="589" alt="Sendto" src="https://github.com/user-attachments/assets/ff8084e9-2f9a-4626-9265-77b5b3fbb13f" />
</p>

---

## ⚡ Техническое

- Сделано на **Godot 4.7**
- Внутри **FFMPEG + FFProbe** — ничего ставить не надо
- Прогресс-бар в реальном времени
- FPS, скорость кодирования, битрейт, Ориентировочное время завершения — всё на экране
- Только Windows 10/11 (SendTo — чисто виндовое колдунство)

---

## ☕ Поддержать

Если WRecode сэкономил тебе время или просто вызвал улыбку:

<p align="center">
  <a href="https://dalink.to/waipek">
    <img src="https://img.shields.io/badge/Support%20me-ff69b4?style=for-the-badge" alt="Support me" />
  </a>
</p>
