extends Spatial

export(float) var mousesense = 0.25
export(int) var maxEngineForce = 100
export(int) var maxBrakingForce = 100
export(int) var torqueForce = 2000

export(float) var turretTurnSpeed = 1
export(float) var barrelTurnSpeed = 0.5

var turretAimingRotation = Vector3()
var barrelAimingRotation = Vector3()

var mousepos = Vector2()
var camIncrement = Vector2()
var screensize = Vector2()

var collPoint = Vector3()
var collObj = Spatial

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
	
	if Input.is_action_pressed("mouse_right"):
		
		$cameraRoot/ClippedCamera/RayCast.enabled = false
		
	else:
		
		$cameraRoot/ClippedCamera/RayCast.enabled = true
		
		collPoint = $cameraRoot/ClippedCamera/RayCast.get_collision_point( ) 
		collObj = $cameraRoot/ClippedCamera/RayCast.get_collider( )
		

func _input(event: InputEvent) -> void:
	# zoom
	if event.is_action_pressed("scroll_up"):
		if $cameraRoot.scale.x > 0.2:
			$cameraRoot.scale *= 0.9
		
	
	if event.is_action_pressed("scroll_down"):
		if $cameraRoot.scale.x < 1.9:
			$cameraRoot.scale *= 1.1
		


func moveForwardBackward():
	
	if Input.is_action_pressed("move_backward"):
		
		if $wheelBaseRoot.brake <= maxBrakingForce:
			$wheelBaseRoot.brake += maxBrakingForce * 0.2
		else:
			$wheelBaseRoot.brake = maxBrakingForce
		
	else:
		
		$wheelBaseRoot.brake = 0
		
	
	if Input.is_action_pressed("move_forward"):
		
		if $wheelBaseRoot.engine_force <= maxEngineForce:
			$wheelBaseRoot.engine_force += maxEngineForce * 0.08
		else:
			$wheelBaseRoot.engine_force = maxEngineForce
		
	else:
		
		$wheelBaseRoot.engine_force = 0.01
		
	
	
	pass

func turnLeftRight():
	
	if Input.is_action_pressed("turn_left"):
		
		var actuallTorque = torqueForce * (torqueForce - $tankBody.linear_velocity.length()* 100)/torqueForce
		
		$tankBody.add_torque(Vector3(0,1,0) * actuallTorque)
		
	
	if Input.is_action_pressed("turn_right"):
		
		var actuallTorque = torqueForce * (torqueForce - $tankBody.linear_velocity.length()* 100)/torqueForce
		
		$tankBody.add_torque(Vector3(0,-1,0) * actuallTorque)
		
	
	pass

var degreePlus
var degreeMinus

func turnTurret():
	
	$tankBody/turretPointer.look_at(collPoint, Vector3(0,1,0))
	
	turretAimingRotation.y = $tankBody/turretPointer.rotation_degrees.y
	
	var floorTurRot = floor($tankBody/turretBody.rotation_degrees.y)
	var floorAimRot = floor(turretAimingRotation.y)
	
	if floorTurRot != floorAimRot:
		
		if floorTurRot >= 0 and floorAimRot >= 0:
			
			if floorTurRot >= floorAimRot:
				
				$tankBody/turretBody.rotate_y(deg2rad(-turretTurnSpeed))
				
			else:
				
				$tankBody/turretBody.rotate_y(deg2rad(turretTurnSpeed))
				
			
		
		if floorTurRot <= 0 and floorAimRot <= 0:
			
			if floorTurRot >= floorAimRot:
				
				$tankBody/turretBody.rotate_y(deg2rad(-turretTurnSpeed))
				
			else:
				
				$tankBody/turretBody.rotate_y(deg2rad(turretTurnSpeed))
				
			
		
		if floorTurRot >= 0 and floorAimRot <= 0:
			
			degreePlus = (179 - floorTurRot) + (180 - abs(floorAimRot))
			degreeMinus = floorTurRot + abs(floorAimRot)
			
			if degreePlus >= degreeMinus:
				
				$tankBody/turretBody.rotate_y(deg2rad(-turretTurnSpeed))
				
			else:
				
				$tankBody/turretBody.rotate_y(deg2rad(turretTurnSpeed))
				
			
		
		if floorTurRot < 0 and floorAimRot >= 0:
			
			degreePlus = abs(floorTurRot) + floorAimRot
			degreeMinus = abs(180 + floorTurRot) + (179 - floorAimRot)
			
			if degreePlus > degreeMinus:
				
				$tankBody/turretBody.rotate_y(deg2rad(-turretTurnSpeed))
				
			else:
				
				$tankBody/turretBody.rotate_y(deg2rad(turretTurnSpeed))
				
		
	

func turnBarrel():
	
	$tankBody/turretBody/barrelPointer.look_at(collPoint, Vector3(1,0,0))
	
	barrelAimingRotation.x = $tankBody/turretBody/barrelPointer.rotation_degrees.x
	
	var floorPointerRot = floor(barrelAimingRotation.x)
	var floorBarrelRot = floor($tankBody/turretBody/barrelBody.rotation_degrees.x)
	
	if floorPointerRot != floorBarrelRot:
		
		if floorPointerRot > floorBarrelRot:
			
			$tankBody/turretBody/barrelBody.rotate_x(deg2rad(barrelTurnSpeed))
			
		else:
			
			$tankBody/turretBody/barrelBody.rotate_x(deg2rad(-barrelTurnSpeed))
			
		
	

func _process(delta):
	
	rotateCamera()
	moveForwardBackward()
	turnLeftRight()
	turnTurret()
	turnBarrel()
