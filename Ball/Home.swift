//
//  Home.swift
//  Don't Drop Me!
//
//  Created by 高宇超 on 7/6/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit
import GameKit

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


let levelNum = 52
let screenHeight: CGFloat = 667
let screenWidth: CGFloat = 375
let gcWorld = "worldBest"

class Home: SKScene, GKGameCenterControllerDelegate {
    
    let startPos = CGPoint(x: 231, y: 555)
    let loadTime: TimeInterval = 4 // 4 seconds for loading the game
    
    var defaults: UserDefaults!
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
    
    var waitDelayAtBegin: TimeInterval = 0.4
    var dropping = false
    var musicSet = false
    var firstTimestampBool = true
    var firstTimestamp: TimeInterval = 0
    var nameShown = false
    
    override func didMove(to view: SKView) {
        
        // Locale.preferredLanguages
        
        defaults = UserDefaults.standard
        waitDelayAtBegin = ballNode == nil ? loadTime : 0.4
        
        if !defaults.bool(forKey: "notGcPlayer") {
            defaults.set(true, forKey: "notGcPlayer")
            defaults.synchronize()
            authPlayer()
        }

        springSys = childNode(withName: "springSys")!
        ballNode = ballNode == nil ? springSys.childNode(withName: "ball") as! SKSpriteNode : ballNode
        radialBall = springSys.childNode(withName: "radialBall") as! SKSpriteNode
        ropeNode = ballNode.childNode(withName: "rope") as! SKSpriteNode
        springField = radialBall.childNode(withName: "springField") as! SKFieldNode
        playLabel = childNode(withName: "playLabel") as! SKLabelNode
        playerName = childNode(withName: "playerName") as! SKLabelNode
        
        level.childNode(withName: "scrollUp")?.zPosition = -5
        if let levels = level.levels { levels.isHidden = true }
        
        if gameScene.home == nil { gameScene.home = self }
        if gameScene.level == nil { gameScene.level = level }
        
        gameScene.passedLevelNum = 0
        var totalTime: Double = 520
        for n in 1...levelNum {
            let board = GKLeaderboard()
            board.timeScope = .allTime
            board.identifier = "level\(n)"
            board.loadScores { (score : [GKScore]?, error:Error?) -> Void in
                if error != nil {
                } else {
                    if let score = board.localPlayerScore {
                        self.gameScene.passedLevelNum += 1
                        let time = Double(score.value) / 1000
                        totalTime -= 10
                        totalTime += time
                        self.defaults.set(time, forKey: "best\(n)")
                        self.defaults.synchronize()
                    }
                }
            }
        }

        nameShown = false
        dropping = false
        firstTimestamp = 0
        firstTimestampBool = true
        springField.isEnabled = true
        ballNode.alpha = 1
        ballNode.position = startPos
        ballNode.physicsBody?.mass = 0.7
        ballNode.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        ballNode.physicsBody?.isDynamic = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if dropping && touches.count == 1 {
            springField.isEnabled = !springField.isEnabled
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if !nameShown && GKLocalPlayer.localPlayer().playerID != nil {
            if let alias = GKLocalPlayer.localPlayer().alias {
                let len = CGFloat(alias.characters.count)
                playerName.text = alias
                playerName.fontSize = 700 / len
                while playerName.frame.width > 300 { playerName.fontSize = playerName.fontSize - 7 }
                playerName.run(SKAction.fadeIn(withDuration: 0.48))
            }
            nameShown = true
        }
        let dy = startPos.y - ballNode.position.y
        ropeNode.xScale = 1 - (dy + 40) / 2000
        let _ = ropeNode.xScale.clamp(0.37, 1)
        
        if firstTimestampBool {
            firstTimestamp = currentTime
            firstTimestampBool = false
        }
        if firstTimestamp > 0 && currentTime - firstTimestamp > waitDelayAtBegin && !dropping {
            if playerName.alpha < 1 {
                playerName.run(SKAction.fadeIn(withDuration: 0.28))
            }

            if GKLocalPlayer.localPlayer().isAuthenticated {
                defaults.set(false, forKey: "notGcPlayer")
                defaults.synchronize()
            }
            ballNode.physicsBody?.isDynamic = true
            dropping = true
        }
        if dropping {
            if let camera = camera {
                camera.position = CGPoint(x: camera.position.x, y: ballNode.position.y)
                let _ = camera.position.y.clamp(screenHeight / 2, -screenHeight / 2)
                if ballNode.physicsBody?.velocity.dy > 0 {
                    ballNode.run(SKAction.fadeIn(withDuration: 0.6))
                    playLabel.run(SKAction.fadeIn(withDuration: 0.6))
                } else if ballNode.physicsBody?.velocity.dy < 0 {
                    let dtime = TimeInterval((ballNode.position.y + screenHeight / 2) / -ballNode.physicsBody!.velocity.dy)
                    let dptime = TimeInterval((ballNode.position.y - 100) / -ballNode.physicsBody!.velocity.dy)
                    ballNode.run(SKAction.fadeOut(withDuration: dtime))
                    playLabel.run(SKAction.fadeOut(withDuration: dptime))
                }
                
                if ballNode.position.y < -screenHeight / 2 - 50 {
                    ballNode.isHidden = true
                    ballNode.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                    ballNode.position = startPos

                    let skView = self.view as SKView!
                    
                    /* Sprite Kit applies additional optimizations to improve rendering performance */
                    skView?.ignoresSiblingOrder = true
                    
                    /* Set the scale mode to scale to fit the window */
                    level.scaleMode = scaleMode
                    level.anchorPoint.x = 0.5

                    
                    if level.home == nil { level.home = self }
                    if level.gameScene == nil { level.gameScene = gameScene }
                    
                    camera.position.y = screenHeight / 2
                    skView?.presentScene(level)
                }
                
                springField.strength += arc4random_uniform(2) == 0 ? 0.1 : -0.1
                let _ = springField.strength.clamp(5.6, 6.6)
            }
        }
    }
    
    func authPlayer() -> Void {
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {
            (view, error) in
            if view != nil {
                self.view!.window?.rootViewController?.present(view!, animated: true, completion: nil)
            }
        }
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
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
