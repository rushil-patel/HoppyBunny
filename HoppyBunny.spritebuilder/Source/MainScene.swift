import Foundation

class MainScene: CCNode, CCPhysicsCollisionDelegate {

    weak var hero: CCSprite!
    weak var gamePhysicsNode: CCPhysicsNode!
    weak var ground1: CCSprite!
    weak var ground2: CCSprite!
    weak var obstaclesLayer: CCNode!
    weak var restartButton: CCButton!
    
    var sinceTouch: CCTime = 0
    var scrollSpeed: CGFloat = 80
    
    //property for Ground mechanism
    var grounds = [CCSprite]() // init empty grounds array
    
    
    //properties for Obstacle mechanism
    var obstacles: [CCNode] = []
    var firstObstaclePosition: CGFloat = 280
    var distanceBetweenObstacles: CGFloat = 160
    
    // game over toggle
    var gameOver = false
    
    // points tracker
    var points: NSInteger = 0
    // score label connection
    weak var scoreLabel: CCLabelTTF!
 
    
    func didLoadFromCCB() {
        userInteractionEnabled = true
        gamePhysicsNode.collisionDelegate  = self
        
        grounds.append(ground1)
        grounds.append(ground2)
        
        for i in 0...2 {
            spawnNewObstacle()
        }
        
    }
    
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero nodeA: CCNode!, goal: CCNode!) -> Bool {
        goal.removeFromParent()
        points++
        scoreLabel.string = String(points)
        return true
    
    }
    
    //called whenever collision type hero collides with collision type level
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, level: CCNode!) -> Bool {
        triggerGameOver()
        return true
    }
    
    func restart() {
        let scene = CCBReader.loadAsScene("MainScene")
        CCDirector.sharedDirector().presentScene(scene)
    }
    
    func triggerGameOver() {
        if (gameOver == false) {
            gameOver = true
            restartButton.visible = true
            scrollSpeed = 0
            hero.rotation = 90
            hero.physicsBody.allowsRotation = false
            
            //just in case
            hero.stopAllActions()
            
            let move = CCActionEaseBackOut(action: CCActionMoveBy(duration: 0.2, position: ccp(0, 4)))
            let moveBack = CCActionEaseBounceOut(action: move.reverse())
            let shakeSequence = CCActionSequence(array:  [move, moveBack])
            runAction(shakeSequence)
        }
    }
    
    func spawnNewObstacle() {
        var prevObstaclePosition = firstObstaclePosition
        if obstacles.count > 0 {
            prevObstaclePosition = obstacles.last!.position.x
        }
        
        //create and add an new obstacle]
        let obstacle = CCBReader.load("Obstacle") as! Obstacle
        obstacle.position = ccp(prevObstaclePosition + distanceBetweenObstacles, 0)
        obstacle.setupRandomPosition()
        
        obstaclesLayer.addChild(obstacle)
        obstacles.append(obstacle)
    }
    
    override func touchBegan(touch: CCTouch!, withEvent event: CCTouchEvent!) {
        if gameOver == false {
            hero.physicsBody.applyImpulse(ccp(0,400))
            hero.physicsBody.applyAngularImpulse(10000)
            sinceTouch = 0
        }
    }
    
    override func update(delta: CCTime) {
        
        //bound y-dir velocity of hero
        let velY = clampf(Float(hero.physicsBody.velocity.y), -Float(CGFloat.max), 200)
        
        //update y-dir velocity of hero
        hero.physicsBody.velocity = ccp(0, CGFloat(velY))
        
        //move hero to the left
        hero.position = ccp(hero.position.x + scrollSpeed * CGFloat(delta), hero.position.y)
        hero.position = ccp(round(hero.position.x), round(hero.position.y))
        
        //scroll camera to the left to follow hero
        gamePhysicsNode.position = ccp(gamePhysicsNode.position.x - scrollSpeed * CGFloat(delta), gamePhysicsNode.position.y)
 
        //FIX: black line artifact
        gamePhysicsNode.position = ccp(round(gamePhysicsNode.position.x), round(gamePhysicsNode.position.y))
        
        //increment delta value
        sinceTouch += delta
        
        //bound hero rotation range
        hero.rotation = clampf(Float(hero.rotation), -30, 90)
        
        
        if hero.physicsBody.allowsRotation {
            let angularVelocity = clampf(Float(hero.physicsBody.angularVelocity), -2, 1)
            hero.physicsBody.angularVelocity = CGFloat(angularVelocity)
        }
        if sinceTouch > 0.3 {
            let impulse = -18000 * delta
            hero.physicsBody.applyAngularImpulse(CGFloat(impulse))
        }
        
        for ground in grounds {
            let groundWorldPosition = gamePhysicsNode.convertToWorldSpace(ground.position)
            let groundScreenPosition = convertToNodeSpace(groundWorldPosition)
            
            if groundScreenPosition.x <= (-ground.contentSize.width) {
                ground.position = ccp(ground.position.x + ground.contentSize.width * 2, ground.position.y)
            }
        }
        
        for obstacle in obstacles.reverse() {
            let obstacleWorldPosition = gamePhysicsNode.convertToWorldSpace(obstacle.position)
            let obstacleScreenPosition = convertToNodeSpace(obstacleWorldPosition)
            //remove if obstacle has passed through the screen and spawn new
            if obstacleScreenPosition.x < -obstacle.contentSize.width {
                
                obstacle.removeFromParent()
                obstacles.removeAtIndex(find(obstacles, obstacle)!)
                spawnNewObstacle()
                
            }
        }
    }
}
