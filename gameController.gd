extends Spatial

export (PackedScene) var bulletScene
var arrayBullets = []
var arrayFlyingBullets = []

export (Array) var arrayTestEnemiesScene
var arrayEnemies = []
var arrayEnemiesModels = []
var arrayMovingEnemies = []
var arrayChasingEnemies = []
export (PackedScene) var armoredEnemyScene

class bullet:
	var damage = 10
	var speed = 0.5
	var model
	var trajectory
	var penetration = 35

class enemy:
	var maxhp = 50
	var currenthp
	var model
	var path
	var follow
	var speed = 0.1
	var lastAngle

var arrayPlayerObjects

onready var noiseSignature = get_node(str($tankScene.get_path()) + "/noiseSignature" )

func tellEnemyToAttack(enemyBody):
	if enemyBody.get_class() == "KinematicBody":
		if str(enemyBody.get_path()).find("Enemy") != -1 or str(enemyBody.get_path()).find("enemy") != -1:
			for enemy in arrayEnemies:
				if enemy.model == enemyBody and arrayChasingEnemies.has(enemy) == false:
					arrayMovingEnemies.erase(enemy)
					arrayChasingEnemies += [enemy]
					enemy.model.behaviour = "attack"
					enemy.model.whoToShoot($tankScene/tankBody)

func spawnEnemies():
	arrayTestEnemiesScene = $spawns.get_children()
	for enemyFromScene in arrayTestEnemiesScene:
		var newEnemy = enemy.new()
		newEnemy.currenthp = newEnemy.maxhp
		newEnemy.model = armoredEnemyScene.instance()
		
		newEnemy.model.connect("requestRoamingPoint", self, "giveRoamingPath")
		newEnemy.model.connect("requestEnemyShoot", self, "testShooting")
		newEnemy.model.sceneCenter = $spawns.global_transform.origin
		
		newEnemy.path = Path.new()
		newEnemy.follow = PathFollow.new()
		newEnemy.follow.loop = false
		newEnemy.follow.rotation_mode = 4
		
		newEnemy.follow.add_child(newEnemy.model)
		newEnemy.path.add_child(newEnemy.follow)
		add_child(newEnemy.path)
		newEnemy.follow.global_transform.origin = enemyFromScene.global_transform.origin
		
		arrayEnemiesModels += [newEnemy.model]
		arrayEnemies += [newEnemy]

func _ready():
	$tankScene.connect("shoot", self, "testShooting")
	noiseSignature.connect("body_entered", self, "tellEnemyToAttack")
	arrayPlayerObjects = [$tankScene/tankBody, $tankScene/wheelBaseRoot]
	############ Test code section
	spawnEnemies()

func stopRoaming(whoAsked):
	for enemy in arrayEnemies:
		if enemy.model == whoAsked:
			arrayMovingEnemies.erase(enemy)
			enemy.follow.rotate_y(PI)
			enemy.model.setTimerIdle()

func giveRoamingPath(coords, whoAsked):
	var path = $Navigation.get_simple_path(whoAsked.global_transform.origin, coords)
	for enemy in arrayEnemies:
		if enemy.model == whoAsked:
			for point in path:
				enemy.path.curve.add_point(point)
			arrayMovingEnemies += [enemy]

func testShooting(muzzle, target):
	var newBullet = bullet.new()
	newBullet.model = bulletScene.instance()
	newBullet.trajectory = target - muzzle
	newBullet.trajectory = newBullet.trajectory.normalized()
	
	add_child(newBullet.model)
	newBullet.model.global_transform.origin = muzzle
	
	arrayFlyingBullets += [newBullet]

func bulletHitEnemyNoArmor(bullet, enemy):
	enemy.currenthp -= bullet.damage
	print("Hit! HP = ", enemy.currenthp, "/", enemy.maxhp)
	
	if enemy.currenthp <= 0:
		print("Enemy dead!")
		arrayEnemiesModels.erase(enemy.model)
		arrayEnemies.erase(enemy)
		remove_child(enemy.path)
		
		arrayMovingEnemies.erase(enemy)
		arrayChasingEnemies.erase(enemy)

func bulletHitArmoredEnemy(bullet, enemy, armor, center, normal):
	var plateVector = normal.global_transform.origin - center.global_transform.origin
	plateVector = plateVector.normalized()
	
	var angle = rad2deg(bullet.trajectory.angle_to(plateVector))
	if angle > 90:
		angle = 180 - angle
	angle = 90 - angle
	
	var efficientArmor = armor.armorThickness / cos(deg2rad(90 - angle))
	var currentEnemy = enemy
	
	if bullet.penetration >= efficientArmor:
		print("Penetration! Bullet pen = ", bullet.penetration, " eff armor = ", efficientArmor)
		bulletHitEnemyNoArmor(bullet, currentEnemy)
	else:
		print("Didn't go through!")
	

func moveFlyingBullets():
	var arrayToErase = []
	
	for bullet in arrayFlyingBullets:
		var bulletCollision = bullet.model.move_and_collide(bullet.trajectory * bullet.speed, false)
		if bulletCollision != null:
			var collider = bulletCollision.get_collider()
			
			arrayToErase += [bullet]
			remove_child(bullet.model)
			
			if arrayPlayerObjects.has(collider):
				PlayerInfo.currenthp -= bullet.damage
				print("Player hit! HP=", PlayerInfo.currenthp, "/", PlayerInfo.maxhp)
				
				if PlayerInfo.currenthp <= 0:
					print("Player dead! Test restore")
					$tankScene/tankBody.global_transform.origin = Vector3(0,2,0)
					$tankScene/wheelBaseRoot.global_transform.origin = Vector3(0,2,0)
					$tankScene/tankBody.rotation_degrees = Vector3(0,0,0)
					$tankScene/wheelBaseRoot.rotation_degrees = Vector3(0,0,0)
					
					PlayerInfo.currenthp = PlayerInfo.maxhp
			else:
				if collider.get_class() == "KinematicBody":
					if arrayEnemiesModels.has(collider):
						for enemy in arrayEnemies:
							if enemy.model == collider:
								bulletHitEnemyNoArmor(bullet, enemy)
				
				if collider.get_class() == "StaticBody":
					if str(collider.get_path()).find("armor") != -1:
						var armoredEnemyModel = collider.get_parent()
						var armorCenter = get_node(str(collider.get_path()) + "/center")
						var armorNormal = get_node(str(collider.get_path()) + "/normal")
						
						var currentEnemy
						
						for enemy in arrayEnemies:
							if enemy.model == armoredEnemyModel:
								currentEnemy = enemy
						
						bulletHitArmoredEnemy(bullet, currentEnemy, collider, armorCenter, armorNormal)
					
	
	for bullet in arrayToErase:
		arrayFlyingBullets.erase(bullet)
	
	arrayToErase.clear()

func movingEnemies():
	var arrayToStop = []
	
	for enemy in arrayMovingEnemies:
		if enemy.follow.unit_offset != 1 and enemy.model.behaviour != "attack":
			enemy.follow.offset += enemy.speed
		else:
			arrayToStop += [enemy]
			enemy.model.setTimerIdle()
	
	for enemy in arrayToStop:
		arrayMovingEnemies.erase(enemy)
	

func chasingPlayer():
	var arrayToStop = []
	
	var playerPos = $Navigation.get_closest_point($tankScene/tankBody.global_transform.origin)
	
	for enemy in arrayChasingEnemies:
		if enemy.model.global_transform.origin.distance_to(playerPos) > 10:
			enemy.path.curve.set_point_position(enemy.path.curve.get_point_count() - 1, playerPos)
			enemy.follow.offset += enemy.speed
		else:
			if playerPos != enemy.follow.global_transform.origin:
				enemy.follow.look_at(playerPos, Vector3(0,1,0))
			enemy.follow.rotate_y(PI)
			enemy.path.curve.set_point_position(enemy.path.curve.get_point_count() - 1, playerPos)
			enemy.follow.offset -= enemy.speed * 1.01

func _process(delta):
	moveFlyingBullets()
	movingEnemies()
	chasingPlayer()



