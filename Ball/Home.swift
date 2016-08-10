//
//  Home.swift
//  Don't Drop Me!
//
//  Created by 高宇超 on 7/6/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit
import GameKit

let levelNum = 15
let screenHeight: CGFloat = 667
let screenWidth: CGFloat = 375
let gcWorld = "worldBest"

class Home: SKScene, GKGameCenterControllerDelegate {
    
    let startPos = CGPoint(x: 217.5, y: 520)
    let loadTime: NSTimeInterval = 0 // 4 seconds for loading the game
    
    var defaults: NSUserDefaults!
    var level: Level! = Level(fileNamed: "Level") as Level!
    var gameScene: GameScene! = GameScene(fileNamed: "GameScene") as GameScene!
    
    var ballNode: SKSpriteNode!
    var radialBall: SKSpriteNode!
    var ropeNode: SKSpriteNode!
    var springField: SKFieldNode!
    var playLabel: SKLabelNode!

    var waitDelayAtBegin: NSTimeInterval = 0.4
    var dropping = false
    var musicSet = false
    var firstTimeStampBool = true
    var firstTimeStamp: NSTimeInterval = 0 // to be 4 but not 0
    
    override func didMoveToView(view: SKView) {
        
        defaults = NSUserDefaults.standardUserDefaults()
        waitDelayAtBegin = ballNode == nil ? loadTime : 0.4
        
        ballNode = childNodeWithName("ball") as! SKSpriteNode
        radialBall = childNodeWithName("radialBall") as! SKSpriteNode
        ropeNode = ballNode.childNodeWithName("rope") as! SKSpriteNode
        springField = radialBall.childNodeWithName("springField") as! SKFieldNode
        playLabel = childNodeWithName("playLabel") as! SKLabelNode

        level.childNodeWithName("scrollUp")?.zPosition = -5
        if let levels = level.levels { levels.hidden = true }
        
        if gameScene.home == nil { gameScene.home = self }
        if gameScene.level == nil { gameScene.level = level }
        
        if !musicSet {
            musicSet = true
            defaults.setBool(true, forKey: "music")
        }
        
        dropping = false
        firstTimeStamp = 0
        firstTimeStampBool = true
        springField.enabled = true
        ropeNode.size.height = 40
        ballNode.alpha = 1
        ballNode.position = startPos
        ballNode.physicsBody?.mass = 0.7
        ballNode.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        ballNode.physicsBody?.dynamic = false
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if dropping {
            for touch in touches {
                let node = nodeAtPoint(touch.locationInNode(self))
                springField.enabled = !springField.enabled
                if node == ballNode {
                    
                }
            }
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        let dy = startPos.y - ballNode.position.y
        ropeNode.size.height = dy + 40
        ropeNode.xScale = 1 - ropeNode.size.height / 2000
        ropeNode.xScale.clamp(0.37, 1)
        
        if firstTimeStampBool {
            firstTimeStamp = currentTime
            firstTimeStampBool = false
        }
        if firstTimeStamp > 0 && currentTime - firstTimeStamp > waitDelayAtBegin {
            ballNode.physicsBody?.dynamic = true
            dropping = true
        }
        if dropping {
            if let camera = camera {
                camera.position = CGPoint(x: camera.position.x, y: ballNode.position.y)
                camera.position.y.clamp(screenHeight / 2, -screenHeight / 2)
                if ballNode.physicsBody?.velocity.dy > 0 {
                    ballNode.runAction(SKAction.fadeInWithDuration(0.6))
                    playLabel.runAction(SKAction.fadeInWithDuration(0.6))
                } else if ballNode.physicsBody?.velocity.dy < 0 {
                    let dtime = NSTimeInterval((ballNode.position.y + screenHeight / 2) / -ballNode.physicsBody!.velocity.dy)
                    let dptime = NSTimeInterval((ballNode.position.y - 100) / -ballNode.physicsBody!.velocity.dy)
                    ballNode.runAction(SKAction.fadeOutWithDuration(dtime))
                    playLabel.runAction(SKAction.fadeOutWithDuration(dptime))
                }
                
                if ballNode.position.y < -screenHeight / 2 - 50 {
                    ballNode.hidden = true
                    ballNode.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                    ballNode.position = startPos

                    let skView = self.view as SKView!
                    
                    /* Sprite Kit applies additional optimizations to improve rendering performance */
                    skView.ignoresSiblingOrder = true
                    
                    /* Set the scale mode to scale to fit the window */
                    level.scaleMode = scaleMode
                    
                    if level.home == nil { level.home = self }
                    if level.gameScene == nil { level.gameScene = gameScene }
                    
                    camera.position.y = screenHeight / 2
                    skView.presentScene(level)
                }
                
                springField.strength += arc4random_uniform(2) == 0 ? 0.1 : -0.1
                springField.strength.clamp(5.6, 6.6)
            }
        }
    }
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
}


// RF: 1 is rotation only, 2 is function only
let objs: [String: [String: String]] = [
    "bounceIR": [
        "halfWidth": "15",
        "rf": "1",
        "categoryBm": "16",
        "name": "Bounce I"
    ],
    "bounceI": [
        "halfWidth": "15",
        "rf": "0",
        "categoryBm": "16",
        "name": "Bounce I"
    ],
    "bounceR": [
        "halfWidth": "21",
        "rf": "1",
        "categoryBm": "2",
        "name": "Bounce"
    ],
    "bounceF": [
        "halfWidth": "21",
        "rf": "2",
        "categoryBm": "2",
        "name": "Bounce"
    ],
    "bounceRF": [
        "halfWidth": "21",
        "rf": "3",
        "categoryBm": "2",
        "name": "Bounce"
    ],
    "ball": [
        "halfWidth": "19",
        "rf": "0",
        "categoryBm": "1",
        "name": "The ball"
    ],
    "shortStickM": [
        "halfWidth": "48",
        "rf": "2",
        "categoryBm": "4",
        "name": "Short stick"
    ],
    "shortStick": [
        "halfWidth": "48",
        "rf": "0",
        "categoryBm": "4",
        "name": "Short stick"
    ],
    "bounce": [
        "halfWidth": "21",
        "rf": "0",
        "categoryBm": "2",
        "name": "Bounce"
    ],
    "stick": [
        "halfWidth": "42",
        "rf": "3",
        "categoryBm": "8",
        "name": "Stick"
    ]
]
