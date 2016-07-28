//
//  Home.swift
//  Don't Drop Me!
//
//  Created by 高宇超 on 7/6/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit

class Home: SKScene {
    
    let screenHeight:CGFloat = 667
    let screenWidth:CGFloat = 375
    
    var level: Level! = Level(fileNamed: "Level") as Level!
    var gameScene: GameScene! = GameScene(fileNamed: "GameScene") as GameScene!
    var defaults: NSUserDefaults!
    
    var buttonPlay: SKLabelNode!
    
    var fromGameScenePassedAll = false
    
    override func didMoveToView(view: SKView) {
        defaults = NSUserDefaults.standardUserDefaults()
        
        buttonPlay = childNodeWithName("buttonPlay") as! SKLabelNode

        if gameScene.home == nil { gameScene.home = self }
        if gameScene.level == nil { gameScene.level = level }

        if fromGameScenePassedAll {
            //print("passed all!")
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let node = nodeAtPoint(touch.locationInNode(self))
            if node.name == "buttonPlay" {
                // goto beginner level
                moveToLevelScene()
            }
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        if camera?.position.y == -screenHeight / 2 {
            let skView = self.view as SKView!
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            level.scaleMode = scaleMode

            if level.home == nil { level.home = self }
            if level.gameScene == nil { level.gameScene = gameScene }
            
            skView.presentScene(level)
            
            camera?.position.y = screenHeight / 2
        }
    }
    
    func moveToLevelScene() -> Void {
        let cameraMove = SKAction.moveTo(CGPoint(x: camera!.position.x, y: -screenHeight / 2), duration: 1)
        camera?.runAction(cameraMove)
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
