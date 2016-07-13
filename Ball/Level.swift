//
//  Level.swift
//  Don't Drop Me!
//
//  Created by 高宇超 on 7/6/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit

let levelNum = 4

class Level: SKScene {
    
    let screenHeight: CGFloat = 667
    
    var chosen = false
    
    var levels = [Int: SKLabelNode!]()
    var homeNode: SKNode!
    var menuNode: SKSpriteNode!
    var bestTimeLabel: SKLabelNode!
    var buttonHome: MSButtonNode!
    var buttonHelp: MSButtonNode!
    
    override func didMoveToView(view: SKView) {
        
        homeNode = childNodeWithName("homeNode")!
        menuNode = childNodeWithName("menu") as! SKSpriteNode
        bestTimeLabel = menuNode.childNodeWithName("bestTimeLabel") as! SKLabelNode
        buttonHome = menuNode.childNodeWithName("buttonHome") as! MSButtonNode
        buttonHelp = menuNode.childNodeWithName("buttonHelp") as! MSButtonNode
        
        for n in 0..<levelNum {
            levels[n] = self.childNodeWithName("level\(n)") as! SKLabelNode
        }
        
        buttonHome.selectedHandler = {
            let path = NSBundle.mainBundle().pathForResource("Home", ofType: "sks")
            let homeRef = SKReferenceNode(URL: NSURL(fileURLWithPath: path!))
            self.homeNode.addChild(homeRef)
            
            let cameraMove = SKAction.moveTo(CGPoint(x: self.camera!.position.x, y: self.screenHeight * 1.5), duration: 1.4)
            self.camera?.runAction(cameraMove)
        }
        buttonHelp.selectedHandler = showHelp
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if chosen {
            return
        }
        for touch in touches {
            let node = nodeAtPoint(touch.locationInNode(self))
            for n in 0..<levelNum {
                if node.name == "level\(n)" {
                    let scene = GameScene(fileNamed: "GameScene") as GameScene!
                    let skView = self.view as SKView!

                    /* Sprite Kit applies additional optimizations to improve rendering performance */
                    skView.ignoresSiblingOrder = true

                    /* Set the scale mode to scale to fit the window */
                    scene.scaleMode = .AspectFill
                    
                    let path = NSBundle.mainBundle().pathForResource("Level\(n)", ofType: "sks")
                    let newLevel = SKReferenceNode(URL: NSURL(fileURLWithPath: path!))
                    newLevel.name = node.name!
                    scene.childNodeWithName("levelNode")!.addChild(newLevel)
                    scene.nowLevelNum = n

                    skView.presentScene(scene)
                    chosen = true
                    break
                }
            }
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        if camera?.position.y == screenHeight * 1.5 {
            if let scene = Home(fileNamed: "Home") {
                let skView = self.view as SKView!
                /* Sprite Kit applies additional optimizations to improve rendering performance */
                skView.ignoresSiblingOrder = true
                scene.scaleMode = .AspectFill
                skView.presentScene(scene)
            }
        }
    }
    
    func showHelp() -> Void {
        
    }
}
