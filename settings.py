import os
import sys

from kivy.app import App  # чтобы все писать не с нуля
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.uix.dropdown import DropDown
from kivy.core.window import Window
import subprocess
import json
from pathlib import Path

class Settings(App):
    def build(self):
        self.layout