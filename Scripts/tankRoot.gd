extends Spatial

export (float) var mousesense = 0.25

export (int) var maxEngineForce = 100

export (int) var maxBrakingForce = 1000

export (int) var torqueForce = 2000

export (float) var turretTurnSpeed = 1
export (float) var barrelTurnSpeed = 0.5

var turretAimingRotation = Vector3()
var barrelAimingRotation = Vector3()

var mousepos = Vector2()
var camIncrement = Vector2()
var screensize = Vector2()

var collPoint = Vector3()
var collObj = Spatial

export (NodePath) var noiseSignature

signal shoot

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)



func rotateCamera(cameraRoot, camera, turret, ray):

	screensize = get_viewport().size

	get_viewport().warp_mouse(screensize / 2)


	cameraRoot.global_transform.origin = turret.global_transform.origin
	cameraRoot.global_transform.origin.y = turret.global_transform.origin.y + 0.75

	mousepos = camera.get_viewport().get_mouse_position()

	camIncrement = mousepos - screensize / 2

	cameraRoot.rotation_degrees.x += -camIncrement.y * mousesense
	cameraRoot.rotation_degrees.y += -camIncrement.x * mousesense

	if cameraRoot.rotation_degrees.x >= 40.1:
		cameraRoot.rotation_degrees.x = 40

	if cameraRoot.rotation_degrees.x <= -70.1:
		cameraRoot.rotation_degrees.x = -70

	cameraRoot.rotation.z = 0

	if Input.is_action_pressed("mouse_right"):
		ray.enabled = false
	else:
		ray.enabled = true

		collPoint = ray.get_collision_point()
		collObj = ray.get_collider()


func _input(event: InputEvent) -> void:
	# zoom
	if event.is_action_pressed("scroll_up"):
		if $cameraRoot.scale.x > 0.2:
			$cameraRoot.scale *= 0.9

	if event.is_action_pressed("scroll_down"):
		if $cameraRoot.scale.x < 1.9:
			$cameraRoot.scale *= 1.1
	
	if event.is_action_pressed("mouse_left"):
		var releasePoint = $tankBody/turretBody/barrelBody/muzzlePoint.global_transform.origin
		var targetPoint = $tankBody/turretBody/barrelBody/RayCast.get_collision_point()
		
		emit_signal("shoot", releasePoint, targetPoint)
		$noiseSignature.scale = Vector3(30,30,30)
		$tankBody/testSignature.scale.x = $noiseSignature.scale.x
		$tankBody/testSignature.scale.z = $noiseSignature.scale.z
	
	if event.is_action_pressed("ui_up"):
		$tankBody.global_transform.origin = Vector3(0,2,0)
		$wheelBaseRoot.global_transform.origin = Vector3(0,2,0)
		$tankBody.rotation_degrees = Vector3(0,0,0)
		$wheelBaseRoot.rotation_degrees = Vector3(0,0,0)
	


func moveForwardBackward(wheelBaseRoot):
	if Input.is_action_pressed("move_backward"):
		if wheelBaseRoot.brake <= maxBrakingForce:
			wheelBaseRoot.brake += maxBrakingForce * 0.2
		else:
			wheelBaseRoot.brake = maxBrakingForce
	else:
		wheelBaseRoot.brake = 0

	if Input.is_action_pressed("move_forward"):
		if wheelBaseRoot.engine_force <= maxEngineForce:
			wheelBaseRoot.engine_force += maxEngineForce * 0.08
		else:
			wheelBaseRoot.engine_force = maxEngineForce
	else:
		wheelBaseRoot.engine_force = 0.01
	
	$noiseSignature.global_transform.origin = $tankBody.global_transform.origin

var turnPossible = false

func turnLeftRight(wheelBaseRoot, tankBody):
	for wheel in wheelBaseRoot.arrayWheels:
		wheel = wheelBaseRoot.get_node(wheel)

		if wheel.is_in_contact():
			turnPossible = true
			break
		else:
			turnPossible = false
	
	if turnPossible == true:
		if Input.is_action_pressed("turn_left"):
			var actuallTorque = (
				torqueForce

				* (torqueForce - tankBody.linear_velocity.length() * 100)
				/ torqueForce
			)

			tankBody.add_torque(Vector3(0, 1, 0) * actuallTorque)


		if Input.is_action_pressed("turn_right"):
			var actuallTorque = (
				torqueForce

				* (torqueForce - tankBody.linear_velocity.length() * 100)
				/ torqueForce
			)

			tankBody.add_torque(Vector3(0, -1, 0) * actuallTorque)


func turnTurret(turretPointer, turretBody):
	var degreePlus = 0
	var degreeMinus = 0

	turretPointer.look_at(collPoint, Vector3(0, 1, 0))

	turretAimingRotation.y = turretPointer.rotation_degrees.y

	var floorTurRot = floor(turretBody.rotation_degrees.y)

	var floorAimRot = floor(turretAimingRotation.y)

	if floorTurRot != floorAimRot:
		if floorTurRot >= 0 and floorAimRot >= 0:
			if floorTurRot >= floorAimRot:

				turretBody.rotate_y(deg2rad(-turretTurnSpeed))
			else:
				turretBody.rotate_y(deg2rad(turretTurnSpeed))

		if floorTurRot <= 0 and floorAimRot <= 0:
			if floorTurRot >= floorAimRot:
				turretBody.rotate_y(deg2rad(-turretTurnSpeed))
			else:
				turretBody.rotate_y(deg2rad(turretTurnSpeed))


		if floorTurRot >= 0 and floorAimRot <= 0:
			degreePlus = (179 - floorTurRot) + (180 - abs(floorAimRot))
			degreeMinus = floorTurRot + abs(floorAimRot)

			if degreePlus >= degreeMinus:

				turretBody.rotate_y(deg2rad(-turretTurnSpeed))
			else:
				turretBody.rotate_y(deg2rad(turretTurnSpeed))


		if floorTurRot < 0 and floorAimRot >= 0:
			degreePlus = abs(floorTurRot) + floorAimRot
			degreeMinus = abs(180 + floorTurRot) + (179 - floorAimRot)

			if degreePlus > degreeMinus:

				turretBody.rotate_y(deg2rad(-turretTurnSpeed))
			else:
				turretBody.rotate_y(deg2rad(turretTurnSpeed))

func turnBarrel(barrelPointer, barrelBody, ray):
	barrelPointer.look_at(collPoint, Vector3(1, 0, 0))

	barrelAimingRotation.x = barrelPointer.rotation_degrees.x

	var floorPointerRot = floor(barrelAimingRotation.x)
	var floorBarrelRot = floor(barrelBody.rotation_degrees.x)

	if floorPointerRot != floorBarrelRot:
		if floorPointerRot > floorBarrelRot:
			barrelBody.rotate_x(deg2rad(barrelTurnSpeed))
		else:
			barrelBody.rotate_x(deg2rad(-barrelTurnSpeed))
	
	var targetPoint = ray.get_collision_point()
	
	## Temporary crossfire

	$cameraRoot/ClippedCamera/lblCenter.rect_position = $cameraRoot/ClippedCamera.unproject_position(targetPoint)
	$cameraRoot/ClippedCamera/lblO.rect_position = screensize / 2

func changeNoiseSignatureSpeed(signature, tankbody):
	if tankbody.get_linear_velocity().length() > 1:
		signature.scale = Vector3(1,1,1) * tankbody.get_linear_velocity().length()
	else:
		signature.scale = Vector3(1,1,1)

func _process(delta):
	rotateCamera($cameraRoot, $cameraRoot/ClippedCamera, $tankBody/turretBody, $cameraRoot/ClippedCamera/RayCast)
	moveForwardBackward($wheelBaseRoot)
	turnLeftRight($wheelBaseRoot, $tankBody)
	turnTurret($tankBody/turretPointer, $tankBody/turretBody)
	turnBarrel($tankBody/turretBody/barrelPointer, $tankBody/turretBody/barrelBody, $tankBody/turretBody/barrelBody/RayCast)
	$tankBody/testSignature.scale.x = $noiseSignature.scale.x
	$tankBody/testSignature.scale.z = $noiseSignature.scale.z
	changeNoiseSignatureSpeed($noiseSignature, $tankBody)
	

