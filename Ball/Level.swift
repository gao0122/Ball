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
    var passedLevelNum = 0
    var totalTime: CFTimeInterval = 0
    
    var levels = [Int: SKLabelNode!]()
    var homeNode: SKNode!
    var menuNode: SKSpriteNode!
    var bestTimeLabel: SKLabelNode!
    var buttonHome: MSButtonNode!
    var buttonHelp: MSButtonNode!
    
    var defaults: NSUserDefaults!
    
    override func didMoveToView(view: SKView) {
        
        defaults = NSUserDefaults.standardUserDefaults()
        
        homeNode = childNodeWithName("homeNode")!
        menuNode = childNodeWithName("menu") as! SKSpriteNode
        bestTimeLabel = menuNode.childNodeWithName("bestTimeLabel") as! SKLabelNode
        buttonHome = menuNode.childNodeWithName("buttonHome") as! MSButtonNode
        buttonHelp = menuNode.childNodeWithName("buttonHelp") as! MSButtonNode
        
        passedLevelNum = defaults.integerForKey("passedLevelNum") ?? 0
        if defaults.boolForKey("passedAll") {
            for n in 1...levelNum {
                let levelName = "level\(n)"
                levels[n] = self.childNodeWithName(levelName) as! SKLabelNode
            }
        } else {
            for n in 1...levelNum {
                levels[n] = self.childNodeWithName("level\(n)") as! SKLabelNode
                
                if defaults.boolForKey("pass\(n)") {
                    
                } else {
                    
                }
            }
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
            for n in 1...levelNum {
                if node.name == "level\(n)" || node.name == "level\(n)Area" {
                    if n == 1 || defaults.boolForKey("pass\(n)") || defaults.boolForKey("pass\(n - 1)") {
                        moveToLevelN(n, name: node.name!)
                        break
                    }
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
    
    func moveToLevelN(n: Int, name: String!) -> Void {
        let scene = GameScene(fileNamed: "GameScene") as GameScene!
        let skView = self.view as SKView!
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .AspectFill
        
        let path = NSBundle.mainBundle().pathForResource("Level\(n)", ofType: "sks")
        let newLevel = SKReferenceNode(URL: NSURL(fileURLWithPath: path!))
        newLevel.name = name
        scene.childNodeWithName("levelNode")!.addChild(newLevel)
        scene.nowLevelNum = n
        
        skView.presentScene(scene)
        chosen = true
    }
}
