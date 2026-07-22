class_name CompressionPreview
extends TextureRect

@onready var pixels_slider: HSlider = $"../HBoxContainer/pixels_per_kbps"
@onready var scale_slider: HSlider = $"../HBoxContainer2/min scale_factor"

# --- Shader parameters ---
var _shader: Shader = preload("res://shaders/preview_compression.gdshader")


func _ready() -> void:
	# Create and assign the shader material
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	material = mat
	
	# Connect slider changes
	pixels_slider.value_changed.connect(_update_preview)
	scale_slider.value_changed.connect(_update_preview)
	
	# Apply initial values
	_update_preview()


func _update_preview(_val: float = 0.0) -> void:
	var mat := material as ShaderMaterial
	if not mat:
		return
	
	# quality (1-100): pixels_per_kbps ranges 50-2000
	# Lower pixels_per_kbps = lower quality = more JPEG artifacts
	var quality := int(round(
		1.0 + (pixels_slider.value - pixels_slider.min_value) \
		/ (pixels_slider.max_value - pixels_slider.min_value) * 99.0
	))
	
	# downscale (0.0-1.0): min_scale_factor ranges 0.1-1.0
	# Lower min_scale_factor = more downscale
	var downscale := 1.0 - (scale_slider.value - scale_slider.min_value) \
		/ (scale_slider.max_value - scale_slider.min_value)
	
	mat.set_shader_parameter("quality", quality)
	mat.set_shader_parameter("downscale", downscale)
