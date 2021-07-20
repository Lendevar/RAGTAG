extends Spatial

export (PackedScene) var bulletScene
var arrayBullets = []

class bullet:
	var damage = 10
	var speed = 0.2
	var model
	var trajectory
	var follow

func _ready():
	$tankScene.connect("shoot", self, "shootRequested")


func shootRequested(muzzle, target):
	var newBullet = bullet.new()
	newBullet.model = bulletScene.instance()
	newBullet.trajectory = Path.new()
	newBullet.follow = PathFollow.new()
	newBullet.follow.loop = false
	
	newBullet.trajectory.add_child(newBullet.follow)
	newBullet.follow.add_child(newBullet.model)
	
	newBullet.trajectory.curve.add_point(muzzle)
	newBullet.trajectory.curve.add_point(target)
	
	add_child(newBullet.trajectory)
	newBullet.model.connect("body_entered", self, "bulletHitSomething")
	
	arrayBullets += [newBullet]

func moveBullets():
	var arrayToErase = []
	
	for bullet in arrayBullets:
		bullet.follow.offset += bullet.speed
		
		if bullet.follow.unit_offset == 1:
			remove_child(bullet.trajectory)
			arrayToErase += [bullet]
	
	for bullet in arrayToErase:
		arrayBullets.erase(bullet)
	
	arrayToErase.clear()

func bulletHitSomething(whatIsHit):
	print("Hit detected! ", whatIsHit)

func _process(delta):
	moveBullets()



