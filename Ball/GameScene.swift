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

// RF: 1 is rotation only, 2 is function only
let objs: [String: [String: String]] = [
    "bounceR": [
        "halfWidth": "21",
        "rf": "1",
        "name": "Bounce"
    ],
    "bounceF": [
        "halfWidth": "21",
        "rf": "2",
        "name": "Bounce"
    ],
    "bounceRF": [
        "halfWidth": "21",
        "rf": "3",
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

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let pai = CGFloat(M_PI)
    let screenWidth: CGFloat = 375
    let screenHeidht: CGFloat = 667
    let menuHeight: CGFloat = 65
    let ballRadius: CGFloat = 19
    
    var state: GameState = .Ready {
        didSet {
            if state == .GameOverPass {
                defaults.setBool(true, forKey: "pass\(nowLevelNum)")
            }
        }
    }
    
    var ballNode: Ball!
    var levelNode: SKNode!
    var startNode: SKSpriteNode!
    var endNode: SKSpriteNode!
    var nowNode: SKNode! {
        didSet {
            lastTouchLocation = nowNode.position
            lastTouchNodeLocation = nowNode.position
            objNameLabel.text = objs[nowNode.name!]!["name"]!
            let tt = SKTexture(imageNamed: "\(nowNode.name!)Icon")
            objIconNode.size = tt.size()
            objIconNode.texture = tt
            nowNodeIndex = objNodeIndex[nowNode.name!]!
            
            rotationNode.removeAllActions()
            functionNode.removeAllActions()
            rotationNode.alpha = 0
            functionNode.alpha = 0

            updateRF()
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
    var obstacleLayer: SKNode?
    var stateBar: SKSpriteNode!
    
    var defaults: NSUserDefaults!
    
    var lastTouchNodeLocation: CGPoint!
    var lastTouchLocation: CGPoint!
    
    //var currentTimeStamp: CFTimeInterval = 0
    var pastStaticTime: CFTimeInterval = 0
    var staticTime: CFTimeInterval = 0 // if the ball is static for more than 1s, game over
    var pastTimeStart: CFTimeInterval = 0
    var pastTime: CFTimeInterval = 0
    var bestTime: Double = 0 {
        didSet {
            bestTimeLabel.text = String(format: "Best: %.3f", bestTime)
        }
    }
    var nowLevelNum: Int = 0
    var nowNodeIndex = 0
    var objNodeIndex = [String: Int]()
    
    var multiTouching = false
    var touched = false
    
    var startRotation = false
    var startFunction = false
    var startZR: CGFloat!
    var startPos: CGPoint!
    
    var ballMovingHitWall = false
    var objIconTouchBeganTime: NSTimeInterval!

    override func didMoveToView(view: SKView) {
        
        /* Setup your scene here */
        physicsWorld.contactDelegate = self
        enableMultiTouch()
        defaults = NSUserDefaults.standardUserDefaults()
        
        // node connection
        ballNode = self.childNodeWithName("ball") as! Ball
        levelNode = self.childNodeWithName("levelNode")
        if levelNode.children.count == 0 {
            let n = 3
            let levelPath = NSBundle.mainBundle().pathForResource("Level\(n)", ofType: "sks")
            let newLevel = SKReferenceNode(URL: NSURL(fileURLWithPath: levelPath!))
            newLevel.name = "level\(n)"
            nowLevelNum = n
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
        obstacleLayer = levelNode.childNodeWithName("//obstacleLayer")
        stateBar = menuNode.childNodeWithName("stateBar") as! SKSpriteNode
        
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
                    //self.objNodes.children.obj.children.first!.children.first!.children
                    self.ballNode.physicsBody?.affectedByGravity = true
                    self.state = .Dropping
                    self.nowNode = self.ballNode
                    self.nowNodeIndex = 0
                    if let obstacleLayer = self.obstacleLayer {
                        self.levelNode.addChild(obstacleLayer)
                    }
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
                for touch in touches {
                    let location = touch.locationInNode(self)
                    let node = nodeAtPoint(location)
                    if node.name == nil {
                        print("node name is nil \(node)")
                        return
                    } else if node == rotationNode || node == functionNode ||
                        functionNode == node.parent || rotationNode == node.parent {
                        if node == rotationNode || rotationNode == node.parent {
                            functionNode.runAction(SKAction(named: "fadeOut")!)
                            startRotation = true
                            startZR = nowNode.zRotation
                        } else {
                            rotationNode.runAction(SKAction(named: "fadeOut")!)
                            startFunction = true
                            startPos = location
                            objFunctionBegan()
                        }
                    } else {
                        lastTouchLocation = location
                        rotationNode.runAction(SKAction(named: "fadeOut")!)
                        functionNode.runAction(SKAction(named: "fadeOut")!)
                    }
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
                        if startRotation || startFunction {
                            if startRotation {
                                let dy = nowNode.position.y - location.y
                                let dx = nowNode.position.x - location.x
                                let angle = startZR + atan2(dy, dx)
                                nowNode.zRotation = angle % (pai * 2)

                                rotationNode.position = location
                            } else {
                                objFunctionMoving(location)
                                functionNode.position = location
                            }
                        } else {
                            updateObjMove(location)
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
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let count = touches.count
        
        switch state {
        case .Ready:
            lastTouchNodeLocation = nowNode.position
            
            switch count {
            case 1:
                for touch in touches {
                    let location = touch.locationInNode(self)
                    let node = nodeAtPoint(location)
                    
                    checkStateBarPosition()
                    
                    if let name = node.name {
                        print(name)
                        
                    } else {
                        print("nil")
                    }
                }
                updateRF()
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
        startFunction = false
        startRotation = false
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
            pos.x = pos.x <= ballRadius ? ballRadius : pos.x
            pos.x = pos.x >= screenWidth - ballRadius ? screenWidth - ballRadius : pos.x
            pos.y = pos.y >= screenHeidht - ballRadius ? screenHeidht - ballRadius : pos.y
            pos.y = pos.y <= menuHeight + ballRadius ? menuHeight + ballRadius : pos.y
            ballNode.position = pos
            if isBallInArea(startNode, hard: true) {
                buttonGo.runAction(SKAction(named: "fadeInButtonGo")!)
            } else {
                buttonGo.runAction(SKAction(named: "fadeOutButtonGo")!)
            }
            
            if let beganTime = objIconTouchBeganTime {
                if currentTime - beganTime > 0.48 {
                    objIconNode.objIconLongPress()
                    objIconNode.longTouched = true
                    objIconTouchBeganTime = nil
                }
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
        if state == .GameOverPass {
            if nowLevelNum == levelNum - 1 {
                passedAllLevels()
                return
            } else {
                nowLevelNum += 1
            }
        }
        restart(nowLevelNum)
        state = .Ready
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
        stateBar.alpha = 0
        stateBar.zPosition = 12
        stateBar.hidden = true
        
        rotationNode.alpha = 0
        functionNode.alpha = 0
        
        bestTimeScore()
        timeLabel.text = "0.000"
        objNodes = levelNode.childNodeWithName("//objNodes")
        startNode = levelNode.childNodeWithName("//start") as! SKSpriteNode
        endNode = levelNode.childNodeWithName("//end") as! SKSpriteNode
        obstacleLayer = levelNode.childNodeWithName("//obstacleLayer")
        obstacleLayer?.removeFromParent()
        
        var n = 1
        for obj in objNodes.children {
            objNodeIndex[obj.children.first!.children.first!.name!] = n
            let pos = obj.position
            obj.position = CGPoint(x: 0, y: 0)
            obj.children.first!.children.first!.position = pos
            n += 1
        }
    }
    
    func passedAllLevels() -> Void {
        defaults.setBool(true, forKey: "passedAll")
        if let scene = Home(fileNamed: "Home") {
            let skView = self.view as SKView!
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            scene.scaleMode = .AspectFill
            scene.fromGameScenePassedAll = true
            skView.presentScene(scene)
        }
    }
    
    func bestTimeScore() -> Void {
        bestTime = defaults.doubleForKey("best\(nowLevelNum)") ?? 0
        if pastTime > 0 && Double(pastTime) < bestTime || bestTime == 0 {
            bestTime = Double(pastTime)
        }
        defaults.setDouble(bestTime, forKey: "best\(nowLevelNum)")
        defaults.synchronize()
    }
    
    func angleToRadian(angle: CGFloat) -> CGFloat {
        return pai * angle / 180.0
    }
    
    func radianToAngle(radian: CGFloat) -> CGFloat {
        return radian * 180.0 / pai % 360
    }
    
    func updateRF() -> Void {

        var name = nowNode.parent?.parent?.name
        if nowNode == ballNode {
            name = "ball"
        }
        
        if let rf = Int(objs[name!]!["rf"]!) {
            let r = rf == 1 || rf == 3
            let f = rf > 1

            let c: CGFloat = 100
            let d = CGFloat(Int(objs[nowNode.name!]!["halfWidth"]!)!) + 27
            let pos = nowNode.position
            var rPos = CGPoint(x: pos.x, y: pos.y)
            var fPos = CGPoint(x: pos.x, y: pos.y)
            
            if r && f {
                // both icons show
                if pos.x > 0 && pos.x < screenWidth && pos.y > menuHeight && pos.y < screenHeidht {
                    // inside screen
                    if pos.x > c && pos.x < screenWidth - c && pos.y > c && pos.y < screenHeidht - c / 2 {
                        // centre
                        rPos.x += d
                        fPos.x += -d
                    } else if pos.x <= screenWidth / 2 && pos.y <= screenHeidht / 2 {
                        // bottom left
                        rPos.x += d
                        rPos.y += d / 3
                        fPos.x += d / 3
                        fPos.y += d
                    } else if pos.x >= screenWidth / 2 && pos.y <= screenHeidht / 2 {
                        // bottom right
                        rPos.x += -d
                        rPos.y += d / 3
                        fPos.x += -d / 3
                        fPos.y += d
                    } else if pos.x <= screenWidth / 2 && pos.y >= screenHeidht / 2 {
                        // top left
                        rPos.x += d
                        rPos.y += -d / 3
                        fPos.x += d / 3
                        fPos.y += -d
                    } else if pos.x >= screenWidth / 2 && pos.y >= screenHeidht / 2 {
                        // top right
                        rPos.x += -d
                        rPos.y += -d / 3
                        fPos.x += -d / 3
                        fPos.y += -d
                    }
                } else if pos.y > menuHeight && pos.y < screenHeidht {
                    // top and bottom inside, left and right outside
                    if pos.x <= 0 {
                        // left outside
                        rPos.x += d * 1.5
                        fPos.x += d * 1.5
                    } else if pos.x >= screenWidth {
                        // right outside
                        rPos.x += -d * 1.5
                        fPos.x += -d * 1.5
                    }
                    if pos.y < d + menuHeight {
                        // bottom inside, nearly border corner
                        rPos.y += d
                        fPos.y += d / 3
                    } else if pos.y > screenHeidht - d {
                        // top inside, nearly border corner
                        rPos.y += -d / 3
                        fPos.y += -d
                    } else {
                        // centre area, away from border corner
                        rPos.y += d / 3
                        fPos.y += -d / 3
                    }
                } else if pos.x > 0 && pos.x < screenWidth {
                    // left and right inside, top and bottom outside
                    if pos.y <= menuHeight {
                        // bottom outside
                        rPos.y += d * 1.5
                        fPos.y += d * 1.5
                    } else if pos.y >= screenHeidht {
                        // top outside
                        rPos.y += -d * 1.5
                        fPos.y += -d * 1.5
                    }
                    if pos.x < d {
                        // left inside but nearly border corner
                        rPos.x += d
                        fPos.x += d / 3
                    } else if pos.x > screenWidth - d {
                        // right inside but nearly border corner
                        rPos.x += -d / 3
                        fPos.x += -d
                    } else {
                        // centre area, away from border corner
                        rPos.x += d / 3
                        fPos.x += -d / 3
                    }
                }
            } else if (r && !f) || (!r && f) {
                // one icon shows
                if pos.x < 284 {
                    // left side
                    if pos.y > screenHeidht - c {
                        // top
                        rPos.x += d / 2
                        fPos.x += d / 2
                        rPos.y += -d
                        fPos.y += -d
                    } else if pos.y < c {
                        // bottom
                        rPos.x += d / 2
                        fPos.x += d / 2
                        rPos.y += d
                        fPos.y += d
                    } else {
                        // centre
                        rPos.x += d
                        fPos.x += d
                    }
                } else if pos.y > screenHeidht / 2 {
                    // top right side
                    rPos.x += -d / 2
                    fPos.x += -d / 2
                    rPos.y += -d
                    fPos.y += -d
                } else {
                    // bottom right side
                    rPos.x += -d / 2
                    fPos.x += -d / 2
                    rPos.y += d
                    fPos.y += d
                }
            }
            
            rotationNode.position = rPos
            functionNode.position = fPos

            if r {
                rotationNode.runAction(SKAction(named: "fadeIn")!)
            }
            if f {
                functionNode.runAction(SKAction(named: "fadeIn")!)
            }

        }
    }
    
    func checkStateBarPosition() -> Void {
        if stateBar.alpha != 0 {
            stateBar.runAction(SKAction(named: "fadeOutHide")!)
        }
        stateBar.removeAllChildren()
    }
    
    func updateObjMove(location: CGPoint) -> Void {
        var pos = location + lastTouchNodeLocation - lastTouchLocation
        if nowNode == ballNode {
            // ball hit wall case
            if pos.x <= ballRadius || pos.x >= screenWidth - ballRadius ||
                pos.y >= screenHeidht - ballRadius || pos.y <= menuHeight + ballRadius {
                
                lastTouchNodeLocation = nowNode.position
                pos = location + lastTouchNodeLocation - lastTouchLocation
                lastTouchLocation = location
                
                // preventing first hitwall the ball position will change a lot by lastTouchLocation's big change
                if !ballMovingHitWall {
                    pos = ballNode.position
                }
                
                pos.x = pos.x <= ballRadius ? ballRadius : pos.x
                pos.x = pos.x >= screenWidth - ballRadius ? screenWidth - ballRadius : pos.x
                pos.y = pos.y >= screenHeidht - ballRadius ? screenHeidht - ballRadius : pos.y
                pos.y = pos.y <= menuHeight + ballRadius ? menuHeight + ballRadius : pos.y
                ballMovingHitWall = true
            } else {
                ballMovingHitWall = false
            }
        }
        nowNode.position = pos
    }
    
    func objFunctionMoving(location: CGPoint) -> Void {
        let dy = location.y - functionNode.position.y
        let dx = location.x - functionNode.position.x
        for child in nowNode.children {
            if let bm = child.physicsBody?.categoryBitMask {
                switch Int(bm) {
                case 2:
                    if let bounce = child as? Bounce {
                        if bounce.k < bounce.kMax && dy > 0 || bounce.k > bounce.kMin && dy < 0 {
                            bounce.k += dy / 200
                        }
                        functionLabel("Force degree: \(String(format: "%.3f", bounce.k / bounce.kMax))")
                    }
                case 4:
                    if let shortStick = child as? ShortStick {
                        if shortStick.direction != "left" && dx < 0 {
                            shortStick.direction = "left"
                            nowNode.runAction(SKAction.rotateToAngle(angleToRadian(60), duration: 0.21))
                        } else if shortStick.direction != "right" && dx > 0 {
                            shortStick.direction = "right"
                            nowNode.runAction(SKAction.rotateToAngle(0, duration: 0.21))
                        }
                        functionLabel(shortStick.direction)
                    }
                case 8:
                    if let stick = child as? Stick {
                        if nowNode.xScale < stick.lenMax && dy > 0 {
                            nowNode.xScale += 0.02
                        } else if nowNode.xScale > stick.lenMin && dy < 0 {
                            nowNode.xScale -= 0.02
                        }
                        functionLabel(String(format: "%.2f", stick.size.width * nowNode.xScale))
                    }
                default:
                    break
                }
            }
        }
    }
    
    func objFunctionBegan() -> Void {
        
        stateBar.runAction(SKAction(named: "fadeInHide")!)

        for child in nowNode.children {
            if let bm = child.physicsBody?.categoryBitMask {
                switch Int(bm) {
                case 2:
                    if let bounce = child as? Bounce {
                        functionLabel("Force degree: \(String(format: "%.3f", bounce.k / bounce.kMax))")
                    }
                case 4:
                    if let shortStick = child as? ShortStick {
                        functionLabel(shortStick.direction)
                    }
                case 8:
                    if let stick = child as? Stick {
                        functionLabel(String(format: "%.2f", stick.size.width * nowNode.xScale))
                    }
                default:
                    break
                }
            }
        }
    }
    
    func functionLabel(str: String) -> Void {
        let label = SKLabelNode(text: str)
        label.fontColor = UIColor.blueColor()
        if stateBar.children.count > 0 {
            stateBar.removeAllChildren()
        }
        stateBar.addChild(label)
        label.position = CGPoint(x: 0, y: -10)
    }
}
