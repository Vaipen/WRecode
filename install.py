import os
import sys
from pathlib import Path

def main():
    sendto_path = os.path.join(os.environ['APPDATA'], 'Microsoft', 'Windows', 'SendTo')
    os.makedirs(sendto_path, exist_ok=True)

    converter_script = str(Path(os.path.abspath(__file__)).parent)+r'\converter.py'
    print(converter_script)

    bat_content = f'''@echo off
chcp 1251 > nul
python "{converter_script}" %1
pause'''

    bat_path = os.path.join(sendto_path, 'WRecode convert.bat')
    with open(bat_path, 'w', encoding='cp1251') as f:
        f.write(bat_content)

    print(f"BAT file created: {bat_path}")
    print("Now in 'Share to' would be WRecode convert.bat app")
    print("If you move folder, reinstall app with 'uninstall.py' and 'install.py'")
    input('\n Press Enter to exit... ')
if __name__ == "__main__":
    main()