extends Spatial

export (PackedScene) var bulletScene
var arrayBullets = []
var arrayFlyingBullets = []

export (Array) var arrayTestEnemiesScene
var arrayEnemies = []
var arrayEnemiesModels = []

class bullet:
	var damage = 10
	var speed = 1
	var model
	var trajectory
	var penetration = 35

class enemy:
	var maxhp = 50
	var currenthp
	var model

func _ready():
	$tankScene.connect("shoot", self, "testShooting")
	
	############ Test code section
	
	for enemyFromScene in arrayTestEnemiesScene:
		var newEnemy = enemy.new()
		newEnemy.currenthp = newEnemy.maxhp
		newEnemy.model = get_node(enemyFromScene)
		
		arrayEnemiesModels += [newEnemy.model]
		arrayEnemies += [newEnemy]

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
		remove_child(enemy.model)

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
		var bulletCollision = bullet.model.move_and_collide(bullet.trajectory * bullet.speed)
		if bulletCollision != null:
			var collider = bulletCollision.get_collider()
			
			arrayToErase += [bullet]
			remove_child(bullet.model)
			
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

func _process(delta):
	moveFlyingBullets()



