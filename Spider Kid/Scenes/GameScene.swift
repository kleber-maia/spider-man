//
//  GameScene.swift
//  Spider Kid
//
//  Created by Kleber Maia on 1/21/20.
//  Copyright © 2020 Kleber Maia. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    struct Collision {
        static let spiderMan: UInt32 = 0x1 << 0
        static let bird: UInt32 = 0x1 << 1
        static let web: UInt32 = 0x1 << 2
    }

    /// screen origin in the bottom, left corner of the screen
    let defaultAnchor = CGPoint(x: 0, y: 0)
    let skyBlue = UIColor(red: 118/255, green: 214/255, blue: 255/255, alpha: 1)

    /// animated character
    var spiderMan: SKSpriteNode!
    var isDead = false

    /// deal with device's accelerometer
    var motionManager = CMMotionManager()
    var destinationX = CGFloat(0)

    func didBegin(_ contact: SKPhysicsContact) {
        collisionBetween(contact.bodyA, contact.bodyB)
    }

    override func didMove(to view: SKView) {
        backgroundColor = skyBlue
        anchorPoint = defaultAnchor

        physicsWorld.contactDelegate = self

        buildBuilding()

        startBuildingClouds()

        buildSpiderMan()

        setupMotionManager()

        startBuildingBirds()
    }

    func touchDown(atPoint pos : CGPoint) {
        buildWebBullet(fireTo: pos)
    }
    
    func touchMoved(toPoint pos : CGPoint) {
    }
    
    func touchUp(atPoint pos : CGPoint) {
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }

    override func update(_ currentTime: TimeInterval) {
        guard !isDead else { return }

        /// animate the building forever
        scrollBuilding()
        /// move the character
        moveSpiderMan()
    }
}

// MARK: - Builds parts of the game

extension GameScene {
    func buildBuilding() {
        let texture = SKTexture(imageNamed: "building")
        let scale = texture.size().width <= size.width * 0.8 ? 1 : (texture.size().width / size.width) * 0.8
        let floors = Int(size.height / (texture.size().height * scale))

        for floor in -1...floors+1 {
            let buildingFloor = SKSpriteNode(texture: texture)
            buildingFloor.name = "building"
            buildingFloor.anchorPoint = defaultAnchor
            buildingFloor.setScale(scale)
            buildingFloor.position = CGPoint(x: (size.width - buildingFloor.size.width) / 2, y: CGFloat(floor) * buildingFloor.size.height)
            buildingFloor.zPosition = 100
            addChild(buildingFloor)

            buildingFloor.run(
                SKAction.setTexture(texture, resize: true)
            )
        }
    }

    func buildSpiderMan() {
        // start the game alive
        isDead = false
        /// load the character animation steps
        let spiderManAtlas = SKTextureAtlas(named: "SpiderMan")
        var spiderManTextures = [SKTexture]()
        for textureName in spiderManAtlas.textureNames {
            spiderManTextures.append(SKTexture(imageNamed: textureName))
        }
        /// create the character out of the first animated step
        spiderMan = SKSpriteNode(texture: spiderManAtlas.textureNamed("spiderman"))
        /// make the character animate forever
        spiderMan.run(
            SKAction.repeatForever(
                SKAction.animate(with: spiderManTextures, timePerFrame: 0.5)
            )
        )
        /// make ithe character human
        spiderMan.physicsBody = SKPhysicsBody(circleOfRadius: spiderMan.size.height / 2)
        spiderMan.physicsBody!.categoryBitMask = Collision.spiderMan
        spiderMan.physicsBody!.collisionBitMask = Collision.bird
        spiderMan.physicsBody!.contactTestBitMask = spiderMan.physicsBody!.collisionBitMask
        spiderMan.physicsBody!.affectedByGravity = false
        spiderMan.physicsBody!.isDynamic = true

        /// position the character on the center of the screen
        spiderMan.anchorPoint = defaultAnchor
        spiderMan.setScale(0.1)
        spiderMan.position = CGPoint(x: (size.width - spiderMan.size.width) / 2, y: (size.height - spiderMan.size.height) / 2)
        spiderMan.zPosition = 900
        addChild(spiderMan)
    }

    func buildWebBullet(fireTo: CGPoint) {
        let web = SKSpriteNode(color: .white, size: CGSize(width: 24, height: 3))
        web.anchorPoint = defaultAnchor
        web.position = CGPoint(x: spiderMan.position.x + (spiderMan.size.width / 2), y: spiderMan.position.y)
        web.zPosition = 900

        let opposite = fireTo.y - web.position.y
        let adjacent = fireTo.x - web.position.x
        web.zRotation = atan2(opposite, adjacent)
        addChild(web)

        /// make ithe web a bullet
        web.physicsBody = SKPhysicsBody(circleOfRadius: 1.5)
        web.physicsBody!.categoryBitMask = Collision.web
        web.physicsBody!.collisionBitMask = Collision.bird
        web.physicsBody!.contactTestBitMask = spiderMan.physicsBody!.collisionBitMask
        web.physicsBody!.affectedByGravity = false
        web.physicsBody!.isDynamic = true

        web.run(
            SKAction.move(to: fireTo, duration: 0.25),
            completion: {[weak self] in
                self?.removeChildren(in: [web])
            }
        )
    }

    func destroyBird(node: SKSpriteNode) {
        node.removeAllActions()
        node.run(SKAction.move(to: CGPoint(x: node.position.x, y: -node.size.height), duration: 1.5)) {[weak self] in
            self?.startBuildingBirds()
        }
    }

    func destroySpiderMan() {
        isDead = true

        spiderMan.run(
            SKAction.move(to: CGPoint(x: spiderMan.position.x, y: -spiderMan.size.height), duration: 1),
            completion: {[weak self] in
                guard let self = self else { return }
                self.removeChildren(in: [self.spiderMan])
                self.buildSpiderMan()
            }
        )
    }

    func startBuildingBirds() {
        /// randomly picks right or left side
        let coin = Int.random(in: 1...2)
        /// load the character animation steps
        let birdAtlas = SKTextureAtlas(named: "Bird\(coin)")
        var birdTextures = [SKTexture]()
        for textureName in birdAtlas.textureNames {
            birdTextures.append(SKTexture(imageNamed: textureName))
        }
        /// create the character out of the first animated step
        let bird = SKSpriteNode(texture: birdAtlas.textureNamed(birdAtlas.textureNames.first!))
        /// make the character animate forever
        bird.run(
            SKAction.repeatForever(
                SKAction.animate(with: birdTextures, timePerFrame: 0.1)
            )
        )
        /// randomly picks a y starting position
        let startingY = CGFloat.random(in: 0...size.height)
        /// forces the character to pass by the center of the screen\
        let startInfirstHalf = startingY <= size.height / 2
        let endingY = CGFloat.random(in: (startInfirstHalf ? size.height / 2 : 0)...(startInfirstHalf ? size.height : size.height / 2))
        /// position the character
        bird.anchorPoint = defaultAnchor
        bird.setScale(0.2)
        bird.position = CGPoint(x: (coin == 1 ? -1 : 1) * size.width, y: startingY)
        bird.zPosition = 900
        addChild(bird)
        /// make ithe character a bird
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        bird.physicsBody!.categoryBitMask = Collision.bird
        bird.physicsBody!.collisionBitMask = Collision.spiderMan | Collision.web
        bird.physicsBody!.contactTestBitMask = bird.physicsBody!.collisionBitMask
        bird.physicsBody!.affectedByGravity = false
        bird.physicsBody!.isDynamic = true
        // move the character to hit spider man
        bird.run(
            SKAction.move(to: CGPoint(x: (coin == 1 ? 1 : -1) * size.width + bird.size.width, y: endingY), duration: 5),
            completion: {[weak self] in
                self?.startBuildingBirds()
            }
        )
    }

    /// Builds clouds in a random size, in a random y position and move them from the right to the left of the screen.
    func startBuildingClouds() {
        let cloud = SKSpriteNode(imageNamed: "cloud")
        addChild(cloud)
        cloud.anchorPoint = defaultAnchor

        let y = CGFloat.random(in: 0...size.height)
        cloud.position = CGPoint(x: size.width, y: y)
        cloud.zPosition = 1000

        let scale = CGFloat.random(in: 0.5...1.5)
        cloud.setScale(scale)

        let moveToLeft = SKAction.moveTo(x: -cloud.size.width, duration: 15)
        cloud.run(
            moveToLeft,
            /// when the cloud finishes animating...
            completion: {[weak self] in
                /// ...build a new one
                self?.startBuildingClouds()
            })
    }

    /// Sets up responding for accelerometer in order to move the character around.
    func setupMotionManager() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.01
            motionManager.startAccelerometerUpdates(to: .main) {(data, error) in
                guard let data = data, error == nil else {
                    return
                }
                let currentX = self.spiderMan.position.x
                /// store next movement on the x axis according to the accelerometer.
                self.destinationX = currentX + CGFloat(data.acceleration.x * 150)
            }
        }
    }
}

// MARK: - Make game work

extension GameScene {
    func collisionBetween(_ bodyA: SKPhysicsBody, _ bodyB: SKPhysicsBody) {
        if bodyA.categoryBitMask & Collision.spiderMan == Collision.spiderMan {
            destroySpiderMan()
        } else if bodyB.categoryBitMask & Collision.spiderMan == Collision.spiderMan {
            destroySpiderMan()
        } else if bodyA.categoryBitMask & Collision.web == Collision.web,
                bodyB.categoryBitMask & Collision.bird == Collision.bird {
            destroyBird(node: bodyB.node as! SKSpriteNode)
        } else if bodyB.categoryBitMask & Collision.web == Collision.web,
                bodyA.categoryBitMask & Collision.bird == Collision.bird {
            destroyBird(node: bodyA.node as! SKSpriteNode)
        }

    }

    func moveSpiderMan() {
        guard destinationX >= size.width * 0.05, destinationX <= (size.width * 0.95) - spiderMan.size.width else {
            destinationX = spiderMan.position.x
            return
        }
        let action = SKAction.moveTo(x: destinationX, duration: 0.1)
        spiderMan.run(action)
    }

    /// Animates the building to give the impression the character is moving down.
    func scrollBuilding() {
        enumerateChildNodes(withName: "building", using: ({[weak self](node, error) in
            guard let self = self else { return }

            let buildingFloor = node as! SKSpriteNode
            buildingFloor.position = CGPoint(x: buildingFloor.position.x, y: buildingFloor.position.y + 1)

            if buildingFloor.position.y > self.size.height {
                buildingFloor.position = CGPoint(x: buildingFloor.position.x, y: -buildingFloor.size.height)
            }
        }))
    }
}
