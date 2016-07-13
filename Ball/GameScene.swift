//
//  GameScene.swift
//  Don't Drop Me!
//
//  Created by 高宇超 on 7/5/16.
//  Copyright (c) 2016 Yuchao. All rights reserved.
//

import SpriteKit
import Foundation
import EventKit

enum GameState {
    case Ready, Dropping, Pass, Failed, GameOverPass, GameOverFailed
}

let objNames: [String: String] = [
    "ball": "The ball",
    "stick": "Stick",
    "shortStick": "Short stick",
    "bounce": "Bounce"
]

// 1 is rotation only, 2 is function only
let objRF: [String: Int] = [
    "stick": 3,
    "shortStick": 2,
    "bounce": 3
]

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let screenWidth: CGFloat = 375
    let screenHeidht: CGFloat = 667
    let menuHeight: CGFloat = 65
    let ballRadius: CGFloat = 19
    
    var state: GameState = .Ready
    
    var ballNode: Ball!
    var levelNode: SKNode!
    var startNode: SKSpriteNode!
    var endNode: SKSpriteNode!
    var nowNode: SKNode! {
        didSet {
            lastTouchLocation = nowNode.position
            lastTouchNodeLocation = nowNode.position
            objNameLabel.text = objNames[nowNode.name!]
            let tt = SKTexture(imageNamed: "\(nowNode.name!)Icon")
            objIconNode.size = tt.size()
            objIconNode.texture = tt
            nowNodeIndex = objNodeIndex[nowNode.name!]!
            
            rotationNode.removeFromParent()
            functionNode.removeFromParent()
            nowNode.addChild(rotationNode)
            nowNode.addChild(functionNode)
            if nowNode == ballNode {
                rotationNode.hidden = true
                functionNode.hidden = true
            } else {
                updateRF()
            }
        }
    }
    var menuNode: SKSpriteNode!
    var buttonHome: MSButtonNode!
    var buttonRestart: MSButtonNode!
    var buttonGo: MSButtonNode!
    var timeLabel: SKLabelNode!
    var bestTimeLabel: SKLabelNode!
    var resultLabel: SKLabelNode!
    var objNameLabel: SKLabelNode!
    var objIconNode: MSButtonNode!
    var objNodes: SKNode!
    var levelNumLabel: SKLabelNode!
    var rotationNode: SKSpriteNode!
    var functionNode: SKSpriteNode!
    
    var defaults: NSUserDefaults!
    
    var lastTouchNodeLocation: CGPoint!
    var lastTouchLocation: CGPoint!
    
    var pastStaticTime: CFTimeInterval = 0
    var staticTime: CFTimeInterval = 0 // if the ball is static for more than 1s, game over
    //var currentTimeStamp: CFTimeInterval = 0
    
    var pastTimeStart: CFTimeInterval = 0
    var pastTime: CFTimeInterval = 0
    var bestTime: Double = 0
    var nowLevelNum: Int = 0
    var nowNodeIndex = 0
    var objNodeIndex = [String: Int]()
    
    var multiTouching = false
    var touched = false
    
    override func didMoveToView(view: SKView) {
        
        /* Setup your scene here */
        physicsWorld.contactDelegate = self
        enableMultiTouch()
        defaults = NSUserDefaults.standardUserDefaults()
        if !defaults.boolForKey("hasPlayed") {
            defaults.setBool(true, forKey: "hasPlayed")
        }
        
        // node connection
        ballNode = self.childNodeWithName("ball") as! Ball
        levelNode = self.childNodeWithName("levelNode")
        if levelNode.children.count == 0 {
            let levelPath = NSBundle.mainBundle().pathForResource("Level0", ofType: "sks")
            let newLevel = SKReferenceNode(URL: NSURL(fileURLWithPath: levelPath!))
            newLevel.name = "level0"
            nowLevelNum = 0
            levelNode.addChild(newLevel)
        }
        menuNode = self.childNodeWithName("menu") as! SKSpriteNode
        buttonHome = menuNode.childNodeWithName("buttonHome") as! MSButtonNode
        buttonRestart = menuNode.childNodeWithName("buttonRestart") as! MSButtonNode
        buttonGo = menuNode.childNodeWithName("buttonGo") as! MSButtonNode
        timeLabel = menuNode.childNodeWithName("timeLabel") as! SKLabelNode
        bestTimeLabel = menuNode.childNodeWithName("bestTimeLabel") as! SKLabelNode
        resultLabel = menuNode.childNodeWithName("resultLabel") as! SKLabelNode
        objNameLabel = menuNode.childNodeWithName("objName") as! SKLabelNode
        objIconNode = menuNode.childNodeWithName("objIcon") as! MSButtonNode
        levelNumLabel = self.childNodeWithName("levelNumLabel") as! SKLabelNode
        rotationNode = self.childNodeWithName("rotation") as! SKSpriteNode
        functionNode = self.childNodeWithName("function") as! SKSpriteNode
        
        objNodeIndex["ball"] = 0
        initGame()
        
        buttonHome.selectedHandler = {
            if let scene = Level(fileNamed: "Level") {
                let skView = self.view as SKView!
                /* Sprite Kit applies additional optimizations to improve rendering performance */
                skView.ignoresSiblingOrder = true
                scene.scaleMode = .AspectFill
                skView.presentScene(scene)
            }
        }
        buttonRestart.selectedHandler = {
            self.restart(self.nowLevelNum)
        }
        buttonGo.selectedHandler = {
            if self.state == .GameOverPass || self.state == .GameOverFailed {
                self.gameOverNext()
            } else if self.state == .Ready {
                if self.isBallInArea(self.startNode, hard: true) {
                    self.ballNode.physicsBody?.affectedByGravity = true
                    self.state = .Dropping
                    self.nowNode = self.ballNode
                    self.nowNodeIndex = 0
                    //self.objNodes.children.obj.children.first!.children.first!.children
                }
            }
        }
        objIconNode.selectedHandler = {
            if self.nowNodeIndex == self.objNodes.children.count {
                self.nowNodeIndex = 0
                self.nowNode = self.ballNode
            } else {
                self.nowNode = self.objNodes.children[self.nowNodeIndex].children.first!.children.first!
                
            }
            self.nowNode.runAction(SKAction(named: "scaleToFocus")!)
        }
        self.view!.addGestureRecognizer(UILongPressGestureRecognizer(target: self.objIconNode, action: #selector(MSButtonNode.objIconLongPress(_:))))
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        touched = true
        
        let count = touches.count
        switch state {
        case .Ready:
            switch count {
            case 1:
                multiTouching = false
                disableMultiTouch()
                rotationNode.hidden = true
                functionNode.hidden = true
                for touch in touches {
                    let location = touch.locationInNode(self)
                    let node = nodeAtPoint(location)
                    if node.name == nil {
                        print("node name is nil \(node)")
                        return
                    }
                    
                    lastTouchLocation = location
                }
            case 2:
                multiTouching = true
                for touch in touches {
                    let location = touch.locationInNode(self)
                    print(location)
                    
                }
            default:
                multiTouching = true
            }
            
        default:
            break
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let count = touches.count
        
        switch state {
        case .Ready:
            switch count {
            case 1:
                if !multiTouching {
                    for touch in touches {
                        let location = touch.locationInNode(self)
                        let pos = location + lastTouchNodeLocation - lastTouchLocation
                        nowNode.position = pos
                    }
                }
            case 2:
                for touch in touches {
                    let location = touch.locationInNode(self)
                    print(location)
                    
                }
            default:
                break
            }
            
        default:
            break
        }
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let count = touches.count
        
        switch state {
        case .Ready:
            lastTouchNodeLocation = nowNode.position
            
            switch count {
            case 1:
                updateRF()
                for touch in touches {
                    let location = touch.locationInNode(self)
                    let node = nodeAtPoint(location)
                    print(node.name! ?? "nil")
                }
            case 2:
                for touch in touches {
                    let location = touch.locationInNode(self)
                    print(location)
                }
            default:
                break
            }
            
        case .GameOverFailed, .GameOverPass:
            switch count {
            case 1:
                for touch in touches {
                    let location = touch.locationInNode(self)
                    let node = nodeAtPoint(location)
                    if let nodeName = node.name {
                        if nodeName == "bg" || nodeName == "levelNumLabel" {
                            gameOverNext()
                        }
                    }
                }
            case 2:
                for touch in touches {
                    let location = touch.locationInNode(self)
                    print(location)
                }
            default:
                break
            }
            
        default:
            break
        }
        touched = false
        enableMultiTouch()
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        // maybe cancelled by a phone call or pressing home button
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        //currentTimeStamp = currentTime
        
        switch state {
        case .Ready:
            var pos = ballNode.position
            pos.x = pos.x <= 1 ? 1 : pos.x
            pos.x = pos.x >= screenWidth - 1 ? screenWidth - 1 : pos.x
            pos.y = pos.y >= screenHeidht - ballRadius ? screenHeidht - ballRadius : pos.y
            pos.y = pos.y <= menuHeight + ballRadius ? menuHeight + ballRadius : pos.y
            ballNode.position = pos
            if isBallInArea(startNode, hard: true) {
                buttonGo.runAction(SKAction(named: "fadeInButtonGo")!)
            } else {
                buttonGo.runAction(SKAction(named: "fadeOutButtonGo")!)
            }
            pastTimeStart = currentTime
        case .Dropping:
            if isBallInArea(endNode, hard: true) {
                state = .Pass
                ballNode.physicsBody?.dynamic = false
            } else {
                if isStatic((self.ballNode.physicsBody?.velocity)!) {
                    if staticTime > 0 && currentTime - staticTime > 1.2 {
                        ballNode.physicsBody?.dynamic = false
                        state = .Failed
                    }
                } else if ballNode.position.y < -99 {
                    ballNode.physicsBody?.dynamic = false
                    state = .Failed
                } else {
                    staticTime = currentTime
                }
                pastTime = currentTime - pastTimeStart
                if pastTime > 10.0 {
                    timeLabel.text = "9.999"
                    state = .Failed
                } else {
                    timeLabel.text = "\(String(format: "%.3f", pastTime))"
                }
            }
        case .Failed, .Pass:
            gameOver()
        default:
            break
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let contactA: SKPhysicsBody = contact.bodyA
        let contactB: SKPhysicsBody = contact.bodyB
        
        let nodeA = contactA.node as! SKSpriteNode
        let nodeB = contactB.node as! SKSpriteNode
        
        let categoryA = contactA.categoryBitMask
        let categoryB = contactB.categoryBitMask
        
        // simple bounce
        if categoryA == 1 && categoryB == 2 {
            let bounceNode = nodeB as! Bounce
            contactA.applyImpulse(contact.contactNormal * contact.collisionImpulse * bounceNode.k)
        } else if categoryB == 1 && categoryA == 2 {
            let bounceNode = nodeA as! Bounce
            contactB.applyImpulse(contact.contactNormal * contact.collisionImpulse * bounceNode.k)
        }
    }
    
    func isBallInArea(node: SKSpriteNode, hard: Bool) -> Bool {
        let pos = ballNode.position
        
        let xL = node.position.x - node.size.width / 2 + (hard ? ballRadius : -ballRadius)
        let xR = node.position.x + node.size.width / 2 + (hard ? -ballRadius : ballRadius)
        let yU = node.position.y + node.size.height / 2 + (hard ? -ballRadius : ballRadius)
        let yD = node.position.y - node.size.height / 2 + (hard ? ballRadius : -ballRadius)
        
        return xL < pos.x && xR > pos.x && yU > pos.y && yD < pos.y
    }
    
    func restart(levelN: Int) -> Void {
        levelNode.removeAllChildren()
        let levelPath = NSBundle.mainBundle().pathForResource("Level\(levelN)", ofType: "sks")
        let newLevel = SKReferenceNode(URL: NSURL(fileURLWithPath: levelPath!))
        newLevel.name = "level\(levelN)"
        levelNode.addChild(newLevel)
        if state == .GameOverPass || state == .GameOverFailed {
            menuNode.runAction(SKAction(named: "menuMoveDown")!)
        }
        ballNode.hidden = false
        levelNode.hidden = false
        initGame()
    }
    
    func isStatic(v: CGVector) -> Bool {
        return abs(v.dx) < 0.0005 && abs(v.dy) < 0.0005
    }
    
    func gameOver() -> Void {
        if state == .Failed {
            state = .GameOverFailed
            resultLabel.text = "Failed..."
        } else if state == .Pass {
            bestTimeScore()
            resultLabel.text = "Pass!"
            state = .GameOverPass
        } else {
            return
        }
        ballNode.hidden = true
        levelNode.hidden = true
        menuNode.runAction(SKAction(named: "menuMoveUp")!)
    }
    
    func gameOverNext() -> Void {
        menuNode.runAction(SKAction(named: "menuMoveDown")!)
        if nowLevelNum < levelNum - 1 {
            nowLevelNum += (state == .GameOverPass ? 1 : 0)
            restart(nowLevelNum)
            state = .Ready
        } else {
            passedAllLevels()
        }
    }
    
    func enableMultiTouch() -> Void {
        self.view?.multipleTouchEnabled = true
    }
    
    func disableMultiTouch() -> Void {
        self.view?.multipleTouchEnabled = false
    }
    
    func initGame() -> Void {
        let tt = SKTexture(imageNamed: "ballIcon")
        objIconNode.size = tt.size()
        objIconNode.texture = tt
        objNameLabel.text = "The ball"
        levelNumLabel.text = String(nowLevelNum)
        if nowLevelNum < 10 {
            levelNumLabel.fontSize = 666
            levelNumLabel.position = CGPoint(x: screenWidth / 2, y: 134)
        } else if nowLevelNum > 100 {
            levelNumLabel.fontSize = 384
            levelNumLabel.position = CGPoint(x: screenWidth / 2, y: 250)
        } else if nowLevelNum < 1000 {
            levelNumLabel.fontSize = 248
            levelNumLabel.position = CGPoint(x: screenWidth / 2, y: 284)
        }
        state = .Ready
        pastTime = 0
        pastTimeStart = 0
        pastStaticTime = 0
        staticTime = 0
        touched = false
        multiTouching = false
        ballNode.physicsBody?.dynamic = true
        ballNode.physicsBody?.affectedByGravity = false
        ballNode.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        ballNode.position = CGPoint(x: screenWidth / 2, y: 384) // init position
        lastTouchLocation = ballNode.position
        lastTouchNodeLocation = ballNode.position
        nowNode = ballNode
        nowNodeIndex = 0
        
        bestTimeScore()
        timeLabel.text = "0.000"
        objNodes = levelNode.childNodeWithName("//objNodes")
        startNode = levelNode.childNodeWithName("//start") as! SKSpriteNode
        endNode = levelNode.childNodeWithName("//end") as! SKSpriteNode
        var n = 1
        for obj in objNodes.children {
            objNodeIndex[obj.name!] = n
            let pos = obj.position
            obj.position = CGPoint(x: 0, y: 0)
            obj.children.first!.children.first!.position = pos
            n += 1
        }
    }
    
    func passedAllLevels() -> Void {
        if let scene = Home(fileNamed: "Home") {
            let skView = self.view as SKView!
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            scene.scaleMode = .AspectFill
            skView.presentScene(scene)
        }
    }
    
    func bestTimeScore() -> Void {
        bestTime = defaults.doubleForKey("\(nowLevelNum)")
        if pastTime > 0 && Double(pastTime) < bestTime || bestTime == 0 {
            bestTime = Double(pastTime)
        }
        defaults.setDouble(bestTime, forKey: "\(nowLevelNum)")
        bestTimeLabel.text = String.init(format: "Best: %.3f", bestTime)
    }
    
    func angleToRadian(angle: Double) -> CGFloat {
        return CGFloat(M_PI * angle / 180.0)
    }
    
    func updateRF() -> Void {
        if let rf = objRF[nowNode.name!] {
            let r = rf == 1 || rf == 3
            let f = rf > 1
            
            rotationNode.hidden = !r
            functionNode.hidden = !f
            
            let c: CGFloat = 100
            let d: CGFloat = 52
            let pos = nowNode.position
            var rPos = CGPoint(x: 0, y: 0)
            var fPos = CGPoint(x: 0, y: 0)
            
            if r && f {
                if pos.x > 0 && pos.x < screenWidth && pos.y > menuHeight && pos.y < screenHeidht {
                    if pos.x > c && pos.x < screenWidth - c && pos.y > c && pos.y < screenHeidht - c {
                        rPos.x = d
                        fPos.x = -d
                    } else if pos.x <= screenWidth / 2 && pos.y <= screenHeidht / 2 {
                        rPos.x = d
                        rPos.y = d / 3
                        fPos.x = d / 3
                        fPos.y = d
                    } else if pos.x >= screenWidth / 2 && pos.y <= screenHeidht / 2 {
                        rPos.x = -d
                        rPos.y = d / 3
                        fPos.x = -d / 3
                        fPos.y = d
                    } else if pos.x <= screenWidth / 2 && pos.y >= screenHeidht / 2 {
                        rPos.x = d
                        rPos.y = -d / 3
                        fPos.x = d / 3
                        fPos.y = -d
                    } else if pos.x >= screenWidth / 2 && pos.y >= screenHeidht / 2 {
                        rPos.x = -d
                        rPos.y = -d / 3
                        fPos.x = -d / 3
                        fPos.y = -d
                    }
                } else if pos.y > menuHeight && pos.y < screenHeidht {
                    if pos.x <= 0 {
                        rPos.x = d * 1.5
                        fPos.x = d * 1.5
                    } else if pos.x >= screenWidth {
                        rPos.x = -d * 1.5
                        fPos.x = -d * 1.5
                    }
                    if pos.y < d + menuHeight {
                        rPos.y = d
                        fPos.y = d / 3
                    } else if pos.y > screenHeidht - d {
                        rPos.y = -d / 3
                        fPos.y = -d
                    } else {
                        rPos.y = d / 3
                        fPos.y = -d / 3
                    }
                } else if pos.x > 0 && pos.x < screenWidth {
                    if pos.y <= menuHeight {
                        rPos.y = d * 1.5
                        fPos.y = d * 1.5
                    } else if pos.y >= screenHeidht {
                        rPos.y = -d * 1.5
                        fPos.y = -d * 1.5
                    }
                    if pos.x < d {
                        rPos.x = d
                        fPos.x = d / 3
                    } else if pos.x > screenWidth - d {
                        rPos.x = -d / 3
                        fPos.x = -d
                    } else {
                        rPos.x = d / 3
                        fPos.x = -d / 3
                    }
                }
            } else if (r && !f) || (!r && f) {
                if pos.x < 284 {
                    if pos.y > screenHeidht - c {
                        rPos.x = d / 2
                        fPos.x = d / 2
                        rPos.y = -d
                        fPos.y = -d
                    } else if pos.y < c {
                        rPos.x = d / 2
                        fPos.x = d / 2
                        rPos.y = d
                        fPos.y = d
                    } else {
                        rPos.x = d
                        fPos.x = d
                    }
                } else if pos.y > screenHeidht / 2 {
                    rPos.x = -d / 2
                    fPos.x = -d / 2
                    rPos.y = -d
                    fPos.y = -d
                } else {
                    rPos.x = -d / 2
                    fPos.x = -d / 2
                    rPos.y = d
                    fPos.y = d
                }
            }
            
            rotationNode.position = rPos
            functionNode.position = fPos
        }
    }
    
}
