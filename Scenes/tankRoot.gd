extends Spatial

export(float) var mousesense = 0.25

var mousepos = Vector2()
var camIncrement = Vector2()
var screensize = Vector2()



func _ready():
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	

func rotateCamera():
	
	screensize = get_viewport().size
	
	get_viewport().warp_mouse( screensize / 2 )
	
	$cameraRoot.global_transform.origin = $tankBody.global_transform.origin
	$cameraRoot.global_transform.origin.y = $tankBody.global_transform.origin.y + 0.75
	
	mousepos = $cameraRoot/ClippedCamera.get_viewport().get_mouse_position()
	
	camIncrement = mousepos - screensize / 2 
	
	$cameraRoot.rotation_degrees.x += -camIncrement.y * mousesense
	$cameraRoot.rotation_degrees.y += -camIncrement.x * mousesense
	
	if $cameraRoot.rotation_degrees.x >= 40.1:
		
		$cameraRoot.rotation_degrees.x = 40
	
	if $cameraRoot.rotation_degrees.x <= -70.1:
		
		$cameraRoot.rotation_degrees.x = -70
		
	$cameraRoot.rotation.z = 0
	

func _process(delta):
	
	rotateCamera()
	
