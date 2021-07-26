extends KinematicBody

export(Array) var armorPlates
export(String) var behaviour

export(float) var unitSpeed = 1

export(float) var rotationSpeed = 1
export(Vector3) var sceneCenter

export(float) var accuracy = 0.2

var targetPlayer

func _ready():
	behaviour = "roam"
	set_safe_margin(1)

signal requestRoamingPoint
signal requestEnemyShoot

func _on_timerStart_timeout():
	behaviourChanged(behaviour)

func whoToShoot(target):
	behaviourChanged("attack")
	targetPlayer = target
	$timerShoot.start()


func behaviourChanged(newBehaviour):
	match newBehaviour:
		"roam":
			$rayForwardRoot.global_transform.origin.x = sceneCenter.x + rand_range(-30,30)
			$rayForwardRoot.global_transform.origin.z = sceneCenter.z + rand_range(-30,30)
			$rayForwardRoot/rayForward.force_raycast_update()
			var coords = $rayForwardRoot/rayForward.get_collision_point()
			emit_signal("requestRoamingPoint", coords, self)
		
		"attack":
			pass

func setTimerIdle():
	if $timerIdle.is_stopped() == true:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		$timerIdle.wait_time = rng.randi_range(1, 5)
		$timerIdle.start()

func _on_timerIdle_timeout():
	behaviour = "roam"
	behaviourChanged(behaviour)

func shootingPlayer():
	$rayShoot.look_at(targetPlayer.global_transform.origin, Vector3(0,1,0))
	var whereTo = $rayShoot.get_collision_point()
	whereTo = to_local(whereTo)
	whereTo.x = whereTo.x + whereTo.x * rand_range(-accuracy, accuracy)
	whereTo.y = whereTo.y + whereTo.y * rand_range(-accuracy, accuracy)
	whereTo.z = whereTo.z + whereTo.z * rand_range(-accuracy, accuracy)
	whereTo = to_global(whereTo)
	
	emit_signal("requestEnemyShoot", $rayShoot.global_transform.origin, whereTo)


func _process(delta):
	pass

func _on_timerShoot_timeout():
	shootingPlayer()
