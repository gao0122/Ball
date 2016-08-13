//
//  Home.swift
//  Don't Drop Me!
//
//  Created by 高宇超 on 7/6/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit
import GameKit

let levelNum = 52
let screenHeight: CGFloat = 667
let screenWidth: CGFloat = 375
let gcWorld = "worldBest"

class Home: SKScene, GKGameCenterControllerDelegate {
    
    let startPos = CGPoint(x: 231, y: 555)
    let loadTime: NSTimeInterval = 4 // 4 seconds for loading the game
    
    var defaults: NSUserDefaults!
    var level: Level! = Level(fileNamed: "Level") as Level!
    var gameScene: GameScene! = GameScene(fileNamed: "GameScene") as GameScene!
    
    var ballNode: SKSpriteNode! {
        didSet {
            ballNode.removeFromParent()
            addChild(ballNode)
            ballNode.position = startPos
        }
    }
    var radialBall: SKSpriteNode!
    var ropeNode: SKSpriteNode!
    var springField: SKFieldNode!
    var playLabel: SKLabelNode!
    var springSys: SKNode!
    var playerName: SKLabelNode! {
        didSet {
            playerName.alpha = 0
        }
    }
    
    var waitDelayAtBegin: NSTimeInterval = 0.4
    var dropping = false
    var musicSet = false
    var firstTimestampBool = true
    var firstTimestamp: NSTimeInterval = 0
    var nameShown = false
    
    override func didMoveToView(view: SKView) {
        
        NSLocale.preferredLanguages()
        
        defaults = NSUserDefaults.standardUserDefaults()
        waitDelayAtBegin = ballNode == nil ? loadTime : 0.4
        
        if !defaults.boolForKey("notGcPlayer") {
            defaults.setBool(true, forKey: "notGcPlayer")
            defaults.synchronize()
            authPlayer()
        }

        springSys = childNodeWithName("springSys")!
        ballNode = ballNode == nil ? springSys.childNodeWithName("ball") as! SKSpriteNode : ballNode
        radialBall = springSys.childNodeWithName("radialBall") as! SKSpriteNode
        ropeNode = ballNode.childNodeWithName("rope") as! SKSpriteNode
        springField = radialBall.childNodeWithName("springField") as! SKFieldNode
        playLabel = childNodeWithName("playLabel") as! SKLabelNode
        playerName = childNodeWithName("playerName") as! SKLabelNode
        
        level.childNodeWithName("scrollUp")?.zPosition = -5
        if let levels = level.levels { levels.hidden = true }
        
        if gameScene.home == nil { gameScene.home = self }
        if gameScene.level == nil { gameScene.level = level }
        
        gameScene.passedLevelNum = 0
        var totalTime: Double = 520
        for n in 1...levelNum {
            let board = GKLeaderboard()
            board.timeScope = .AllTime
            board.identifier = "level\(n)"
            board.loadScoresWithCompletionHandler { (score : [GKScore]?, error:NSError?) -> Void in
                if error != nil {
                } else {
                    if let score = board.localPlayerScore {
                        self.gameScene.passedLevelNum += 1
                        let time = Double(score.value) / 1000
                        totalTime -= 10
                        totalTime += time
                        self.defaults.setDouble(time, forKey: "best\(n)")
                        self.defaults.synchronize()
                    }
                }
            }
        }

        nameShown = false
        dropping = false
        firstTimestamp = 0
        firstTimestampBool = true
        springField.enabled = true
        ballNode.alpha = 1
        ballNode.position = startPos
        ballNode.physicsBody?.mass = 0.7
        ballNode.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        ballNode.physicsBody?.dynamic = false
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if dropping && touches.count == 1 {
            springField.enabled = !springField.enabled
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        if !nameShown && GKLocalPlayer.localPlayer().playerID != nil {
            if let alias = GKLocalPlayer.localPlayer().alias {
                let len = CGFloat(alias.characters.count)
                playerName.text = alias
                playerName.fontSize = 700 / len
                while playerName.frame.width > 300 { playerName.fontSize = playerName.fontSize - 7 }
                playerName.runAction(SKAction.fadeInWithDuration(0.48))
            }
            nameShown = true
        }
        let dy = startPos.y - ballNode.position.y
        ropeNode.xScale = 1 - (dy + 40) / 2000
        ropeNode.xScale.clamp(0.37, 1)
        
        if firstTimestampBool {
            firstTimestamp = currentTime
            firstTimestampBool = false
        }
        if firstTimestamp > 0 && currentTime - firstTimestamp > waitDelayAtBegin && !dropping {
            if playerName.alpha < 1 {
                playerName.runAction(SKAction.fadeInWithDuration(0.28))
            }

            if GKLocalPlayer.localPlayer().authenticated {
                defaults.setBool(false, forKey: "notGcPlayer")
                defaults.synchronize()
            }
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
                    level.anchorPoint.x = 0.5

                    
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
    
    func authPlayer() -> Void {
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {
            (view, error) in
            if view != nil {
                self.view!.window?.rootViewController?.presentViewController(view!, animated: true, completion: nil)
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
    "bounceIR2": [
        "halfWidth": "15",
        "rf": "1",
        "categoryBm": "16",
        "name": "Bounce I"
    ],
    "bounceIR3": [
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
    "bounceI2": [
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
    "bounceR2": [
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
    "bounceF2": [
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
    "bounceRF2": [
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
    "shortStickM2": [
        "halfWidth": "48",
        "rf": "2",
        "categoryBm": "4",
        "name": "Short stick"
    ],
    "shortStickM3": [
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
    "bounce2": [
        "halfWidth": "21",
        "rf": "0",
        "categoryBm": "2",
        "name": "Bounce"
    ],
    "bounce3": [
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
    ],
    "stick2": [
        "halfWidth": "42",
        "rf": "3",
        "categoryBm": "8",
        "name": "Stick"
    ]
]
