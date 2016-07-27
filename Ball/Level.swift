//
//  Level.swift
//  Don't Drop Me!
//
//  Created by 高宇超 on 7/6/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit

let levelNum = 15

class Level: SKScene {
    
    let screenHeight: CGFloat = 667
    
    var gameScene: GameScene!
    var home: Home!
    
    var chosen = false
    var passedLevelNum = 0
    var totalTime: Double = 0
    
    var gameLevelNode: SKNode!
    var homeNode: SKNode!
    var menuNode: SKNode!
    var bestTimeLabel: SKLabelNode!
    var buttonHome: MSButtonNode!
    var buttonHelp: MSButtonNode!
    
    var defaults: NSUserDefaults!
    
    var refHome: SKReferenceNode!
    var refLevels = [Int: SKReferenceNode!]()

    override func didMoveToView(view: SKView) {
        
        defaults = NSUserDefaults.standardUserDefaults()
        chosen = false

        /* Set the scale mode to scale to fit the window */
        gameScene.scaleMode = scaleMode
        if gameScene.level == nil { gameScene.level = self }
        gameLevelNode = gameScene.childNodeWithName("levelNode")!
        
        homeNode = childNodeWithName("homeNode")!
        if refHome == nil {
            refHome = SKReferenceNode(URL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Home", ofType: "sks")!))
            homeNode.addChild(self.refHome)
        }
        
        menuNode = childNodeWithName("menu")!
        bestTimeLabel = menuNode.childNodeWithName("bestTimeLabel") as! SKLabelNode
        buttonHome = menuNode.childNodeWithName("buttonHome") as! MSButtonNode
        buttonHelp = menuNode.childNodeWithName("buttonHelp") as! MSButtonNode

        passedLevelNum = defaults.integerForKey("passedLevelNum") ?? 0
        totalTime = defaults.doubleForKey("totalTime") ?? 0
        
        // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! FOR TEST ONLY !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        if !defaults.boolForKey("unlockedAll") { defaults.setBool(true, forKey: "unlockedAll") }
        
        for n in 1...levelNum {
            loadLevelN(n)
            if defaults.boolForKey("passedAll") {
                // passed all - UI
            } else if defaults.boolForKey("unlockedAll") {
                // unlocked - UI
            } else {
                if defaults.boolForKey("pass\(n)") {
                    // pass UI
                } else {
                    // locked UI
                }
            }
        }
        
        buttonHome.selectedHandler = {
            let cameraMove = SKAction.moveTo(CGPoint(x: self.camera!.position.x, y: self.screenHeight * 1.5), duration: 1)
            self.camera?.runAction(cameraMove)
        }
        buttonHelp.selectedHandler = showHelp
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if chosen { return }
        for touch in touches {
            let node = nodeAtPoint(touch.locationInNode(self))
            for n in 1...levelNum {
                if node.name == "level\(n)" || node.name == "level\(n)Area" {
                    if n == 1 || defaults.boolForKey("pass\(n)") || defaults.boolForKey("pass\(n - 1)") || defaults.boolForKey("unlockedAll") {
                        
                        moveToLevelN(n, name: node.name!)
                        break
                    }
                }
            }
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        if camera?.position.y == screenHeight * 1.5 {
            let skView = self.view as SKView!
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.showsPhysics = showPhy
            skView.ignoresSiblingOrder = true
            home.scaleMode = scaleMode
            skView.presentScene(home)
            camera?.position.y = screenHeight / 2
        }
    }
    
    func showHelp() -> Void {
        
    }
    
    func moveToLevelN(n: Int, name: String!) -> Void { 
        
        gameLevelNode.removeAllChildren()
        gameLevelNode.addChild(refLevels[n]!.copy() as! SKReferenceNode)
        gameScene.nowLevelNum = n
        
        let skView = self.view as SKView!
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        skView.showsPhysics = showPhy
        skView.showsNodeCount = showNodes
        
        skView.presentScene(gameScene, transition: SKTransition.crossFadeWithDuration(0.7))
        chosen = true
    }
    
    func loadLevelN(n: Int) -> Void {
        if refLevels[n] == nil {
            refLevels[n] = SKReferenceNode(URL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Level\(n)", ofType: "sks")!))
            refLevels[n]!.name = "level\(n)"
        }
    }

}
