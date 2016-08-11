//
//  Level.swift
//  Don't Drop Me!
//
//  Created by 高宇超 on 7/6/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit
import GameKit

class Level: SKScene, GKGameCenterControllerDelegate {
    
    let fontPass = "GillSans"
    let fontDefault = "GillSans-Light"
    
    var gameScene: GameScene!
    var home: Home!
    
    var chosen = false
    var totalTime: Double = 0
    
    var gameLevelNode: SKNode!
    var homeNode: SKNode!
    var menuNode: SKNode!
    var bestTimeLabel: SKLabelNode!
    var buttonHome: MSButtonNode!
    var buttonGC: MSButtonNode!
    var levels: SKNode!
    
    var defaults: NSUserDefaults!
    
    var refHome: SKReferenceNode!
    var refLevels = [Int: SKReferenceNode!]()

    var scrollBegan = false
    var lastLevelPos: CGPoint!
    var lastTouchPos: CGPoint!
    
    var fromGameScenePassedAll = false
    var firstTimestamp: NSTimeInterval = -1
    
    var gcd = false
    
    override func didMoveToView(view: SKView) {

        defaults = NSUserDefaults.standardUserDefaults()
        chosen = false
        scrollBegan = false
        
        if fromGameScenePassedAll {
            // pass all 
        }

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
        buttonGC = menuNode.childNodeWithName("gameCenter") as! MSButtonNode
        levels = childNodeWithName("levels")!
        levels.position = CGPoint(x: screenWidth / 2, y: 366)
        levels.hidden = false
        levels.alpha = 0
        levels.runAction(SKAction.afterDelay(0.19, performAction: SKAction.fadeInWithDuration(0.42)))
        childNodeWithName("scrollUp")?.zPosition = 5
        
        bestTimeLabel.alpha = 0
        totalTime = 520
        firstTimestamp = -1
        fromGameScenePassedAll = false

        // FOR TEST ONLY!!!
        //if !defaults.boolForKey("unlockedAll") { defaults.setBool(true, forKey: "unlockedAll") }
        
        checkLevels()
        buttonHome.selectedHandler = {
            let cameraMove = SKAction.moveTo(CGPoint(x: self.camera!.position.x, y: screenHeight * 1.5), duration: 1)
            self.camera?.runAction(cameraMove)
        }
        buttonGC.selectedHandler = gameCenter
        
        checkTimeScore()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if GKLocalPlayer.localPlayer().authenticated {
            defaults.setBool(false, forKey: "notGcPlayer")
            defaults.synchronize()
        }
        if levels.alpha < 1 { levels.runAction(SKAction.fadeInWithDuration(0.21)) }
        if chosen { return }
        if touches.count == 1 {
            let touch = touches.first!
            let pos = touch.locationInNode(self)  
            lastLevelPos = levels.position
            lastTouchPos = pos
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if touches.count == 1 {
            scrollBegan = true
            let touch = touches.first!
            let pos = touch.locationInNode(self)
            levels.position.y = pos.y - lastTouchPos.y + lastLevelPos.y
            levels.position.y.clamp(366, 800)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if scrollBegan {
            if touches.count == 1 {
                scrollBegan = false
            }
        } else if touches.count == 1 {
            let touch = touches.first!
            let pos = touch.locationInNode(self)
            let node = nodeAtPoint(pos)
            for n in 1...levelNum {
                if node.name == "level\(n)" || node.name == "level\(n)Area" {
                    if n <= 15 || defaults.doubleForKey("best\(n)") < 10 || defaults.doubleForKey("best\(n - 1)") < 10  || defaults.boolForKey("unlockedAll") {
                        
                        moveToLevelN(n, name: node.name!)
                        return
                    }
                }
            }
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        if firstTimestamp < 0 {
            firstTimestamp = currentTime
        } else {
            let dtime = currentTime - firstTimestamp
            if (dtime > 4 && dtime < 4.23) || (dtime > 7 && dtime < 7.23) {
                // do sth at 4th seconds and 7th seconds
            }
        }
        if camera?.position.y == screenHeight * 1.5 {
            let skView = self.view as SKView!
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.showsPhysics = showPhy
            skView.ignoresSiblingOrder = true
            home.scaleMode = scaleMode
            home.ballNode.removeAllActions()
            home.ballNode.hidden = false
            home.ballNode.alpha = 1
            home.ballNode.position = home.startPos
            home.ballNode.physicsBody?.dynamic = false
            self.home.playLabel.removeAllActions()
            self.home.playLabel.runAction(SKAction.fadeInWithDuration(0.2))
            skView.presentScene(home)
            camera?.position.y = screenHeight / 2
        }
    }
    
    func moveToLevelN(n: Int, name: String!) -> Void {
        checkTimeScore()
        if refLevels[n] == nil { return }
        gameLevelNode.removeAllChildren()
        gameLevelNode.addChild(refLevels[n]!.copy() as! SKReferenceNode)
        gameScene.objState = ObjState(levelNum: n)
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
            if let path = NSBundle.mainBundle().pathForResource("Level\(n)", ofType: "sks") {
                refLevels[n] = SKReferenceNode(URL: NSURL(fileURLWithPath: path))
                refLevels[n]!.name = "level\(n)"
            }
        }
    }
    
    func checkTimeScore() -> Void {
        var total: Double = 520
        for n in 1...levelNum {
            let time = defaults.doubleForKey("best\(n)")
            if time < 10 {
                total -= 10
                total += time
            }
        }
        totalTime = total
        defaults.setDouble(total, forKey: "totalTime")
        defaults.synchronize()
    
        //let change: dispatch_block_t = {}
        if self.totalTime == 1 {
            self.bestTimeLabel.text = String(format: "%.3f", self.totalTime) + " second"
        } else {
            self.bestTimeLabel.text = String(format: "%.3f", self.totalTime) + " seconds"
        }
        bestTimeLabel.runAction(SKAction.fadeInWithDuration(0.23))
    }
    
    func gameCenter() -> Void {
        if GKLocalPlayer.localPlayer().authenticated {
            showLeaderBoard()
        } else {
            authPlayer()
        }
    }
    
    func showLeaderBoard() -> Void {
        let viewController = self.view!.window?.rootViewController
        let gcvc = GKGameCenterViewController()
        gcvc.viewState = GKGameCenterViewControllerState.Leaderboards
        
        gcvc.gameCenterDelegate = self
        viewController?.presentViewController(gcvc, animated: true, completion: nil)
    }
    
    func authPlayer() -> Void {
        if !gcd {
            gcd = true

            let localPlayer = GKLocalPlayer.localPlayer()
            localPlayer.authenticateHandler = {
                (view, error) in
                if view != nil {
                    self.view!.window?.rootViewController?.presentViewController(view!, animated: true, completion: nil)
                }
            }
        } else {
            showLeaderBoard()
        }
    }
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }

    func checkLevels() -> Void {
        let green = UIColor(red: 28 / 256, green: 242 / 256, blue: 118 / 256, alpha: 1)
        self.bestTimeLabel.runAction(SKAction.fadeOutWithDuration(0.12))
        for n in 1...levelNum {
            let node = levels.childNodeWithName("level\(n)") as! SKLabelNode
            var score = defaults.doubleForKey("best\(n)")
            if score == 0 {
                defaults.setDouble(10, forKey: "best\(n)")
                defaults.synchronize()
                score = 10
            }
            
            loadLevelN(n)
            
            if defaults.boolForKey("passedAll") {
                // passed all - UI
                node.fontName = fontPass
                node.fontColor = green
            } else {
                if score < 10 {
                    // pass UI
                    node.fontName = fontPass
                    node.fontColor = green
                } else {
                    // locked UI
                    if score == 10 && defaults.doubleForKey("best\(n - 1)") < 10 {
                        node.fontName = fontPass
                        node.fontColor = UIColor.whiteColor()
                    } else {
                        node.fontName = fontDefault
                        node.fontColor = UIColor.whiteColor()
                    }
                }
                if defaults.boolForKey("unlockedAll") || n <= 15 {
                    // unlocked - UI
                    node.fontName = fontPass
                }
            }   
        }
    }
}
