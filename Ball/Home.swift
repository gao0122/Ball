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
    
    var defaults: NSUserDefaults!
    
    var buttonPlay: SKLabelNode!
    
    var hasPlayed = true
    var fromGameScenePassedAll = false
    
    override func didMoveToView(view: SKView) {
        defaults = NSUserDefaults.standardUserDefaults()
        hasPlayed = defaults.boolForKey("hasPlayed")
        
        buttonPlay = childNodeWithName("buttonPlay") as! SKLabelNode
        
        if fromGameScenePassedAll {
            //print("passed all!")
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let node = nodeAtPoint(touch.locationInNode(self))
            if node.name == "buttonPlay" {
                if hasPlayed {
                    moveToLevelScene()
                } else {
                    // goto beginner level
                    
                }
            }
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        if camera?.position.y == -screenHeight / 2 {
            let scene = Level(fileNamed: "Level") as Level!
            let skView = self.view as SKView!
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            skView.presentScene(scene)
        }
    }
    
    func moveToLevelScene() -> Void {
        let cameraMove = SKAction.moveTo(CGPoint(x: camera!.position.x, y: -screenHeight / 2), duration: 1.4)
        camera?.runAction(cameraMove)
    }
}