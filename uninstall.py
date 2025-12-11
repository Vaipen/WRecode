import os
import sys
from pathlib import Path

def main():
    sendto_path = os.path.join(os.environ['APPDATA'], 'Microsoft', 'Windows', 'SendTo')
    bat_filename = 'WRecode convert.bat'
    bat_path = os.path.join(sendto_path, bat_filename)

    if os.path.exists(bat_path):
        try:
            os.remove(bat_path)
            print(f'WRecode removed: {bat_path}')
        except Exception as e:
            print(f'Error duruing uninstallation {bat_path} -> {e}')

    else:
        print(f'File {bat_path} not found in Send to folder')

    input('\n Press Enter to exit... ')

if __name__ == "__main__":
    main()