extends Node
var high := Color.hex(0xf6f7ebff)
var mid := Color.hex(0xe94f37ff)
var low := Color.hex(0xff393e41)
@onready var background: ColorRect = $"../Background"

func _ready() -> void:
	background.material.set("shader_parameter/u_color_low",low)
	background.material.set("shader_parameter/u_color_mid_red",mid)
	background.material.set("shader_parameter/u_color_high",high)
	
	
func _update() -> void:
	pass
