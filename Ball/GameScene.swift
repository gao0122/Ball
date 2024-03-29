//
//  GameScene.swift
//  Don't Drop Me!
//
//  Created by 高宇超 on 7/5/16.
//  Copyright (c) 2016 Yuchao. All rights reserved.
//

import SpriteKit
import GameKit

enum GameState {
    case ready, dropping, pass, failed, gameOverPass, gameOverFailed
}

enum TutorialState {
    case done,
    go, introStart, introGoal, icon, introIcon, touchMoving,
    iconLongPress, beforeIconLongPress, iconLongPressNext, function, fNext,
    tapBounce
}

struct ObjState {
    var levelNum: Int!
    var objPos: [String: CGPoint]
    var objClass: [String: SKNode]
    
    init(levelNum: Int) {
        self.levelNum = levelNum
        self.objPos = [String: CGPoint]()
        self.objClass = [String: SKNode]()
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate, GKGameCenterControllerDelegate {
    
    let pai = CGFloat(Double.pi)
    let menuHeight: CGFloat = 65
    let ballRadius: CGFloat = 19
    
    var state: GameState = .ready
    
    var level: Level!
    var home: Home!
    
    var ballNode: Ball!
    var levelNode: SKNode!
    var startNode: SKSpriteNode! {
        didSet {
            startNode.color = SKColor(red: 28 / 256, green: 242 / 256, blue: 118 / 256, alpha: 1)
            cropRoundCorner(radius: 5, startNode)
        }
    }
    var endNode: SKSpriteNode! {
        didSet {
            endNode.color = SKColor(red: 255 / 256, green: 48 / 256, blue: 44 / 256, alpha: 1)
            cropRoundCorner(radius: 5, endNode)
            if nowLevelNum == 49 {
                let end = endNode.parent!
                let left = SKAction.move(to: CGPoint(x: 180, y: end.position.y), duration: 1)
                let right = SKAction.move(to: CGPoint(x: 333, y: end.position.y), duration: 1)
                let lr = SKAction.sequence([left, right])
                left.timingMode = SKActionTimingMode.easeIn
                right.timingMode = SKActionTimingMode.easeOut
                end.run(SKAction.repeatForever(lr))
            }
        }
    }
    var nowNode: SKNode! {
        didSet {
            lastTouchLocation = nowNode.position
            lastTouchNodeLocation = nowNode.position
            objNameLabel.text = objs[nowNode.name!]!["name"]!
            let tt = SKTexture(imageNamed: "\(nowNode.name!)Icon")
            objIconNode.size = tt.size()
            objIconNode.texture = tt
            var name = nowNode.name!
            if nowNode != ballNode {
                name = (nowNode.parent?.parent?.name)!
            }
            nowNodeIndex = objNodeIndex[name]!
            
            rotationNode.removeAllActions()
            functionNode.removeAllActions()
            rotationNode.alpha = 0
            functionNode.alpha = 0
            
            updateRF()
        }
    }
    var menuNode: SKNode!
    var buttonHome: MSButtonNode!
    var buttonRestart: MSButtonNode!
    var buttonGo: MSButtonNode!
    var timeLabel: SKLabelNode!
    var bestTimeLabel: SKLabelNode!
    var rankLabelLevel: SKLabelNode!
    var rankLabelTime: SKLabelNode!
    var objNameLabel: SKLabelNode!
    var objIconNode: MSButtonNode!
    var objNodes: SKNode!
    var levelNumLabel: SKLabelNode!
    var rotationNode: SKSpriteNode!
    var functionNode: SKSpriteNode!
    var obstacleLayer: SKNode? {
        didSet {
            if nowLevelNum == 52 {
                let pr = CGPoint(x: 250, y: 432)
                let pl = CGPoint(x: 125, y: 432)
                let l = SKAction.move(to: pl, duration: 1)
                let r = SKAction.move(to: pr, duration: 1)
                let lr = SKAction.sequence([l, r])
                let act = SKAction.repeatForever(lr)
                l.timingMode = SKActionTimingMode.easeInEaseOut
                r.timingMode = SKActionTimingMode.easeInEaseOut
                obstacleLayer?.children.first!.run(act)
            }
        }
    }
    var stateBar: SKSpriteNode!
    var tutorialLayer: SKNode?
    var tutorialLayerBg: SKSpriteNode?
    var scoreBoard: SKSpriteNode!
    var resultNode: SKLabelNode!
    var resultRank: SKLabelNode!
    var buttonGC: MSButtonNode!
    
    var defaults: UserDefaults!
    var totalTime: Double = 0
    var passedLevelNum = 0
    
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
    var nowLevelNum: Int! {
        didSet {
            if nowLevelNum > 0 { objState.levelNum = nowLevelNum }
        }
    }
    var nowNodeIndex = 0
    var objNodeIndex = [String: Int]()
    
    var multiTouching = false
    var touched = false
    
    var startRotation = false
    var startFunction = false
    var startZR: CGFloat!
    var startPos: CGPoint!
    
    var ballMovingHitWall = false
    var objIconTouchBeganTime: TimeInterval!
    var longPressObjIconUpdateRF = false
    
    var bounceFunctionV1: CGVector?
    var bounceFunctionV2: CGVector?
    
    var objState: ObjState!

    var levelTutorial: [Int: [TutorialState]]!
    let levelTutorialStates: [Int: [TutorialState]] = [
        1: [.done, .go, .touchMoving, .introIcon, .icon, .introGoal, .introStart],
        2: [.done, .go, .touchMoving, .function, .icon, .iconLongPressNext, .iconLongPress, .beforeIconLongPress, .icon],
        3: [.done, .fNext, .function, .tapBounce],
    ]
    
    var tutorialState: TutorialState = .done {
        didSet {
            self.childNode(withName: "//tutorialHelp")?.removeFromParent()
            switch tutorialState {
            case .go:
                tutorialGo()
            case .introStart:
                introStartLabelActions()
            case .introGoal:
                introGoalLabelActions()
            case .icon:
                tutorialIcon()
            case .introIcon:
                introIconActions()
            case .touchMoving:
                tutorialTouchMoving(CGPoint(x: screenWidth / 2, y: 250))
            case .beforeIconLongPress:
                tutorialBeforeIconLongPress()
            case .iconLongPress:
                tutorialIconLongPress()
            case .iconLongPressNext:
                tutorialIconLongPressNext()
            case .function:
                tutorialFunctionIcon()
            case .fNext:
                tutorialFunctionNext()
            case .tapBounce:
                tutorialTapBounce()
            case .done:
                tutorialLayerBg?.run(SKAction.fadeOut(withDuration: 0.23))
            }
        }
    }
    
    override func didMove(to view: SKView) {
        
        /* Setup your scene here */
        physicsWorld.contactDelegate = self
        
        enableMultiTouch()
        defaults = UserDefaults.standard
        
        // node connection
        ballNode = self.childNode(withName: "ball") as! Ball
        levelNode = self.childNode(withName: "levelNode")
        menuNode = self.childNode(withName: "menu")!
        buttonHome = menuNode.childNode(withName: "buttonHome") as! MSButtonNode
        buttonRestart = menuNode.childNode(withName: "buttonRestart") as! MSButtonNode
        buttonGo = menuNode.childNode(withName: "buttonGo") as! MSButtonNode
        timeLabel = menuNode.childNode(withName: "timeLabel") as! SKLabelNode
        bestTimeLabel = menuNode.childNode(withName: "bestTimeLabel") as! SKLabelNode
        rankLabelLevel = menuNode.childNode(withName: "rankResultLevel") as! SKLabelNode
        rankLabelTime = menuNode.childNode(withName: "rankResultTime") as! SKLabelNode
        objNameLabel = menuNode.childNode(withName: "objName") as! SKLabelNode
        objIconNode = menuNode.childNode(withName: "objIcon") as! MSButtonNode
        levelNumLabel = self.childNode(withName: "levelNumLabel") as! SKLabelNode
        rotationNode = self.childNode(withName: "rotation") as! SKSpriteNode
        functionNode = self.childNode(withName: "function") as! SKSpriteNode
        obstacleLayer = levelNode.childNode(withName: "//obstacleLayer")
        stateBar = menuNode.childNode(withName: "stateBar") as! SKSpriteNode
        scoreBoard = self.childNode(withName: "scoreBoard") as! SKSpriteNode
        resultNode = scoreBoard.childNode(withName: "resultNode") as! SKLabelNode
        resultRank = menuNode.childNode(withName: "rankResultRanking") as! SKLabelNode
        buttonGC = menuNode.childNode(withName: "gameCenter") as! MSButtonNode
        
        menuNode.childNode(withName: "menuBgd")!.alpha = 0.892
        
        levelTutorial = levelTutorialStates
        
        initGame()
        
        buttonHome.selectedHandler = {
            self.scoreBoardAndMenuMoveOut()
            self.levelNode.removeAllChildren()
            
            let skView = self.view as SKView!
            self.level.scaleMode = self.scaleMode
            self.level.anchorPoint.x = 0.5
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView?.ignoresSiblingOrder = true
            skView?.presentScene(self.level, transition: SKTransition.doorway(withDuration: 0.8))
        }
        buttonRestart.selectedHandler = {
            if self.state == .gameOverPass || self.state == .gameOverFailed {
                if self.state == .gameOverPass {
                    self.nowLevelNum = self.nowLevelNum - 1
                }
                self.gameOverNext()
            } else {
                self.restart(self.nowLevelNum)
            }
        }
        buttonGo.selectedHandler = {
            if self.state == .gameOverPass || self.state == .gameOverFailed {
                self.gameOverNext()
            } else if self.state == .ready {
                if self.isBallInArea(self.startNode, hard: true) {
                    //self.objNodes.children.obj.children.first!.children.first!.children
                    if self.tutorialState == .done {
                        self.buttonGoSelector()
                    }
                }
            }
        }
        objIconNode.selectedHandler = {
            if self.state == .ready {
                if self.tutorialState == .done {
                    self.buttonObjIconSelector()
                }
            }
        }
        buttonGC.selectedHandler = showLeaderBoard
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        if tutorialState == .touchMoving {
            if touches.count == 1 {
                let touch = touches.first!
                lastTouchLocation = touch.location(in: self)
                let label = childNode(withName: "//tutorialMovingLabel") as! SKLabelNode
                    rotationNode.run(SKAction(named: "fadeOut")!)
                functionNode.run(SKAction(named: "fadeOut")!)
                label.text = "Drop the stick there"
                let arrow = SKSpriteNode(texture: SKTextureAtlas(named: "assets").textureNamed("arrowIcon"))
                label.addChild(arrow)
                arrow.name = "tutorialArrow"
                arrow.position -= CGPoint(x: 98, y: 41)
                arrow.zRotation = angleToRadian(180)
                arrow.zPosition = 50
                arrow.alpha = 0
                arrow.run(SKAction.fadeIn(withDuration: 0.23))

                let drop = SKShapeNode(rect: CGRect(origin: CGPoint(x: -40, y: -60), size: CGSize(width: 80, height: 120)), cornerRadius: 4.8)
                drop.name = "tutorialDrop"
                drop.fillColor = UIColor.black
                drop.strokeColor = UIColor.black
                drop.alpha = 0
                drop.zPosition = -52
                drop.position = CGPoint(x: -100, y: -124)
                drop.run(SKAction.fadeAlpha(to: 0.32, duration: 0.23))
                label.addChild(drop)
                if nowLevelNum == 2 {
                    drop.position = CGPoint(x: 77.5, y: 488) - label.position
                    drop.yScale = 0.54
                    arrow.zRotation = 0
                    arrow.position = drop.position - CGPoint(x: 0, y: 56)
                }
            }
            return
        }
        if tutorialState != .done && tutorialState != .function {
            return
        } else if let help = childNode(withName: "//tutorialHelpEnd") {
            // if player taps too fast it will miss fade out actions
            help.run(SKAction.fadeOut(withDuration: 0.23))
            help.removeFromParent()
            return
        }
        
        touched = true
        
        let count = touches.count
        switch state {
        case .ready:
            switch count {
            case 1:
                multiTouching = false
                disableMultiTouch()
                for touch in touches {
                    let location = touch.location(in: self)
                    let node = atPoint(location)
                    if node.name == nil {
                        print("node name is nil \(node)")
                        return
                    } else if node == rotationNode || node == functionNode ||
                        functionNode == node.parent || rotationNode == node.parent {
                        if node == rotationNode || rotationNode == node.parent {
                            if tutorialState == .function { break }
                            functionNode.run(SKAction(named: "fadeOut")!)
                            startRotation = true
                            // fix bug that the rotation icon is not at the same y line as nowNode
                            let dy = nowNode.position.y - location.y
                            let dx = nowNode.position.x - location.x
                            startZR = nowNode.zRotation - atan2(dy, dx)
                        } else {
                            if tutorialState == .function { tutorialStateBar() }
                            rotationNode.run(SKAction(named: "fadeOut")!)
                            startFunction = true
                            startPos = location
                            objFunctionBegan()
                        }
                    } else if tutorialState != .function {
                        lastTouchLocation = location
                        rotationNode.run(SKAction(named: "fadeOut")!)
                        functionNode.run(SKAction(named: "fadeOut")!)
                    }
                }
            case 2:
                multiTouching = true
                for touch in touches {
                    let location = touch.location(in: self)
                    print(location)
                    
                }
            default:
                multiTouching = true
            }
        default:
            break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if tutorialState != .done && tutorialState != .function && tutorialState != .touchMoving {
            return
        }

        let count = touches.count
        
        switch state {
        case .ready:
            switch count {
            case 1:
                if !multiTouching {
                    for touch in touches {
                        let location = touch.location(in: self)
                        if startRotation || startFunction {
                            if startRotation {
                                let dy = nowNode.position.y - location.y
                                let dx = nowNode.position.x - location.x
                                let angle = startZR + atan2(dy, dx)
                                nowNode.zRotation = angle.truncatingRemainder(dividingBy: (pai * 2))
                                
                                rotationNode.position = location
                            } else {
                                objFunctionMoving(location)
                                functionNode.position = location
                            }
                        } else if tutorialState != .function {
                            updateObjMove(location)
                        }
                    }
                }
            case 2:
                for touch in touches {
                    let location = touch.location(in: self)
                    print(location)
                    
                }
            default:
                break
            }
            
        default:
            break
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if tutorialState != .done && tutorialState != .function {
            if tutorialState == .touchMoving {
                if touches.count == 1 {
                    lastTouchNodeLocation = nowNode.position
                    if let drop = childNode(withName: "//tutorialDrop") as? SKShapeNode {
                        let label = childNode(withName: "//tutorialMovingLabel") as! SKLabelNode
                        let w = drop.frame.width
                        let h = drop.frame.height
                        let p = drop.position + label.position
                        let np = nowNode.position
                        if abs(np.x - p.x) < w / 2 - 37 && abs(np.y - p.y) < h / 2 - 24 {
                            popLastTutorialState()
                            drop.run(SKAction.fadeOut(withDuration: 0.21))
                        } else {
                            let label = childNode(withName: "//tutorialMovingLabel") as! SKLabelNode
                            label.text = "Hold the blank and move"
                            label.childNode(withName: "tutorialArrow")?.removeFromParent()
                            label.childNode(withName: "tutorialDrop")?.removeFromParent()
                        }
                    } else {
                        let label = childNode(withName: "//tutorialMovingLabel") as! SKLabelNode
                        label.text = "Hold the blank and move"
                        label.childNode(withName: "tutorialArrow")?.removeFromParent()
                        label.childNode(withName: "tutorialDrop")?.removeFromParent()
                    }
                
                    if nowLevelNum == 2 { updateRF() }
                }
            } else {
                let p =
                    tutorialState != .icon &&
                        tutorialState != .go &&
                        tutorialState != .iconLongPress &&
                        tutorialState != .tapBounce
                if p {
                    if tutorialState == .fNext {
                        levelNode.childNode(withName: "tutorialHelpEnd")?.run(
                            SKAction.fadeOut(withDuration: 0.23))
                        levelNode.childNode(withName: "tutorialHelpEnd")?.removeFromParent()
                    }
                    popLastTutorialState()
                }
            }
            return
        }

        let count = touches.count
        
        switch state {
        case .ready:
            lastTouchNodeLocation = nowNode.position
            
            switch count {
            case 1:
                for touch in touches {
                    let location = touch.location(in: self)
                    let node = atPoint(location)
                    
                    checkStateBar()
                    
                    if let name = node.name {
                        print(name)
                        if tutorialState == .function && (node == functionNode || node.parent == functionNode) {
                            levelNode.childNode(withName: "tutorialState")?.run(SKAction.fadeOut(withDuration: 0.84))
                            popLastTutorialState()
                        }
                    } else {
                        print("nil")
                    }
                }
                updateRF()
            case 2:
                for touch in touches {
                    let location = touch.location(in: self)
                    print(location)
                }
            default:
                break
            }
            
        case .gameOverFailed, .gameOverPass:
            switch count {
            case 1:
                for touch in touches {
                    let location = touch.location(in: self)
                    let node = atPoint(location)
                    if let nm = node.name {
                        if nm == "bg" || nm == "levelNumLabel" || nm == "scoreBoard" || nm == "resultNode" {
                            gameOverNext()
                        }
                    }
                }
            case 2:
                for touch in touches {
                    let location = touch.location(in: self)
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
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // maybe cancelled by a phone call or pressing home button
        if event != nil {
            touchesEnded(touches, with: event!)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        //currentTimeStamp = currentTime
        
        switch state {
        case .ready:
            var pos = ballNode.position
            pos.x = pos.x <= ballRadius ? ballRadius : pos.x
            pos.x = pos.x >= screenWidth - ballRadius ? screenWidth - ballRadius : pos.x
            pos.y = pos.y >= screenHeight - ballRadius ? screenHeight - ballRadius : pos.y
            pos.y = pos.y <= menuHeight + ballRadius ? menuHeight + ballRadius : pos.y
            ballNode.position = pos
            if isBallInArea(startNode, hard: true) /*&& noOverlap()*/ {
                buttonGo.run(SKAction(named: "fadeInButtonGo")!)
            } else {
                buttonGo.run(SKAction(named: "fadeOutButtonGo")!)
            }
            
            if let beganTime = objIconTouchBeganTime {
                if currentTime - beganTime > 0.48 {
                    objIconNode.objIconLongPress()
                    objIconNode.longTouched = true
                    objIconTouchBeganTime = nil
                }
            }
            
            if longPressObjIconUpdateRF && nowNode.position == CGPoint(x: 187.5, y: 384) {
                updateRF()
                longPressObjIconUpdateRF =  false
            }
            
            pastTimeStart = currentTime
        case .dropping:
            if isBallInArea(endNode, hard: true) {
                state = .pass
                ballNode.physicsBody?.isDynamic = false
            } else {
                if isStatic((self.ballNode.physicsBody?.velocity)!) {
                    if staticTime > 0 && currentTime - staticTime > 1.2 {
                        ballNode.physicsBody?.isDynamic = false
                        state = .failed
                    }
                } else if ballNode.position.y < -99 {
                    ballNode.physicsBody?.isDynamic = false
                    state = .failed
                } else {
                    staticTime = currentTime
                }
                pastTime = currentTime - pastTimeStart
                if pastTime > 10.0 {
                    timeLabel.text = "9.999"
                    state = .failed
                } else {
                    timeLabel.text = "\(String(format: "%.3f", pastTime))"
                }
            }
        case .failed, .pass:
            gameOver()
        default:
            break
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactA: SKPhysicsBody = contact.bodyA
        let contactB: SKPhysicsBody = contact.bodyB
        contactA.usesPreciseCollisionDetection = true
        contactB.usesPreciseCollisionDetection = true
        
        var nodeA = contactA.node!
        var nodeB = contactB.node!
        if let node = nodeA as? SKSpriteNode {
            nodeA = node
        }
        if let node = nodeB as? SKSpriteNode {
            nodeB = node
        }
        
        let categoryA = contactA.categoryBitMask
        let categoryB = contactB.categoryBitMask
        
        if state == .dropping {
            
            // bounce
            if categoryA == 1 && categoryB == 2 {
                let bounceNode = nodeB as! Bounce
                contactA.applyImpulse(contact.contactNormal * contact.collisionImpulse * bounceNode.k)
            } else if categoryB == 1 && categoryA == 2 {
                let bounceNode = nodeA as! Bounce
                contactB.applyImpulse(contact.contactNormal * contact.collisionImpulse * bounceNode.k)
            }
            
            // invisible obstacle
            if categoryA == 1 && categoryB == 3 {
                nodeB.parent!.run(SKAction(named: "fadeHitObstacle")!)
            } else if categoryB == 1 && categoryA == 3 {
                nodeA.parent!.run(SKAction(named: "fadeHitObstacle")!)
            }
            
            // bounceI
            if categoryA == 1 && categoryB == 16 {
                let bounceNode = nodeB as! BounceI
                contactA.applyImpulse(contact.contactNormal * bounceNode.k)
            } else if categoryB == 1 && categoryA == 16 {
                let bounceNode = nodeA as! BounceI
                contactB.applyImpulse(contact.contactNormal * bounceNode.k)
            }
            
        } else if state == .ready {
            
            // showing bounce functions at the state bar
            if categoryB == 5 {
                if contactB.node?.name == "smallBall1" {
                    bounceFunctionV1 = bounceFunctionV1! * (-1)
                    contactB.velocity = bounceFunctionV1!
                } else if contactB.node?.name == "smallBall2" {
                    bounceFunctionV2 = bounceFunctionV2! * (-1)
                    contactB.velocity = bounceFunctionV2!
                }
            } else if categoryA == 5 {
                if contactB.node?.name == "smallBall1" {
                    bounceFunctionV1 = bounceFunctionV1! * (-1)
                    contactB.velocity = bounceFunctionV1!
                } else if contactB.node?.name == "smallBall2" {
                    bounceFunctionV2 = bounceFunctionV2! * (-1)
                    contactB.velocity = bounceFunctionV2!
                }
            }
        }
    }
    
    func isBallInArea(_ node: SKSpriteNode, hard: Bool) -> Bool {
        let pos = ballNode.position
        let xL = node.position.x - node.size.width / 2 + (hard ? ballRadius : -ballRadius)
        let xR = node.position.x + node.size.width / 2 + (hard ? -ballRadius : ballRadius)
        let yU = node.position.y + node.size.height / 2 + (hard ? -ballRadius : ballRadius)
        let yD = node.position.y - node.size.height / 2 + (hard ? ballRadius : -ballRadius)
        return xL < pos.x && xR > pos.x && yU > pos.y && yD < pos.y
    }
    
    func restart(_ levelN: Int) -> Void {
        if levelNode.children.count > 0 { levelNode.removeAllChildren() }
        
        if levelN <= levelNum {
            let newLevel = level.refLevels[levelN]!.copy() as! SKReferenceNode
            levelNode.addChild(newLevel)
            initGame()
        } else {
            buttonHome.selectedHandler()
        }
    }
    
    func isStatic(_ v: CGVector) -> Bool {
        return abs(v.dx) < 0.0005 && abs(v.dy) < 0.0005
    }
    
    func gameOver() -> Void {
        if state == .failed {
            state = .gameOverFailed
            if nowLevelNum > 3 {
                // save the states of all objects to reload next time
                saveObjsState()
            }
            resultNode.text = "FAIL"
            resultNode.fontSize = 132
            resultNode.fontColor = endNode.color
        } else if state == .pass {
            resultNode.text = "PASS"
            resultNode.fontSize = 120
            resultNode.fontColor = startNode.color
            bestTime = defaults.double(forKey: "best\(nowLevelNum)")
            if bestTime == 0 { bestTime = 10 }
            bestTimeScore()
            state = .gameOverPass
        } else {
            return
        }
        passedLevelNumCount()
        let localPlayer = GKLocalPlayer.localPlayer()
        if localPlayer.isAuthenticated {
            let board = GKLeaderboard()
            board.timeScope = .allTime
            board.identifier = "level\(nowLevelNum)"
            board.loadScores(completionHandler: { error in
                if error != nil {
                    // print error
                } else {
                    if let n = board.localPlayerScore?.rank {
                        var s = ""
                        switch n / 10 {
                        case 1:
                            s = "st"
                        case 2:
                            s = "nd"
                        case 3:
                            s = "rd"
                        default:
                            s = "th"
                            break
                        }
                        self.resultRank.text = "\(n)" + s
                    } else {
                        self.resultRank.text = "No rank"
                    }
                }
            })
            
        } else {
            resultRank.text = "No rank"
        }
    
    
        rankLabelLevel.text = "\(passedLevelNum) levels"
        if passedLevelNum == 1 {
            rankLabelLevel.text = "1 level"
        }
        totalTime = defaults.double(forKey: "totalTime")
        rankLabelTime.text = String(format: "%.3f", totalTime) + " seconds"
        if totalTime == 1 {
            rankLabelTime.text = "1.000 second"
        }
        ballNode.isHidden = true
        ballNode.position = CGPoint(x: -50, y: 50)
        levelNode.removeAllChildren()
        scoreBoardAndMenuMoveIn()
    }
    
    func gameOverNext() -> Void {
        scoreBoardAndMenuMoveOut()
        
        var reload = false
        if state == .gameOverPass {
            if passedLevelNum == levelNum && nowLevelNum == levelNum {
                passedAllLevels()
                return
            } else {
                nowLevelNum = nowLevelNum + 1
            }
        } else {
            reload = true
        }
        
        restart(nowLevelNum)
        state = .ready
        if nowLevelNum > 3 && reload {
            reloadObjsState()
        }
    }
    
    func scoreBoardAndMenuMoveIn() -> Void {
        if let menuNode = menuNode.childNode(withName: "menuBgd") as? SKSpriteNode {
            self.menuNode.run(SKAction(named: "menuMoveUp")!)
            menuNode.physicsBody = SKPhysicsBody(rectangleOf: menuNode.size)
            menuNode.physicsBody?.isDynamic = false
            menuNode.physicsBody?.affectedByGravity = false
            scoreBoard.physicsBody = SKPhysicsBody(rectangleOf: scoreBoard.size)
            scoreBoard.physicsBody?.isDynamic = true
            scoreBoard.physicsBody?.affectedByGravity = true
            
            let tapTodo = scoreBoard.childNode(withName: "tapTodo") as! SKLabelNode
            if nowLevelNum < 5 {
                tapTodo.removeAllActions()
                tapTodo.run(SKAction(named: "fadeInAndOut")!)
            } else {
                tapTodo.removeAllActions()
                tapTodo.run(SKAction.fadeOut(withDuration: 0.1))
            }
        }
    }
    
    func scoreBoardAndMenuMoveOut() -> Void {
        if scoreBoard.physicsBody != nil {
            let tapTodo = scoreBoard.childNode(withName: "tapTodo") as! SKLabelNode
            if nowLevelNum < 5 {
                tapTodo.removeAllActions()
                tapTodo.run(SKAction.fadeOut(withDuration: 0.32))
            }
            scoreBoard.physicsBody = nil
            let ani = SKAction.move(to: CGPoint(x: screenWidth / 2, y: 872), duration: 0.6)
            ani.timingMode = SKActionTimingMode.easeOut
            scoreBoard.run(ani)
            menuNode.run(SKAction(named: "menuMoveDown")!)
            menuNode.childNode(withName: "menuBgd")!.physicsBody = nil
        }
    }
    
    func enableMultiTouch() -> Void {
        self.view?.isMultipleTouchEnabled = true
    }
    
    func disableMultiTouch() -> Void {
        self.view?.isMultipleTouchEnabled = false
    }
    
    func cropRoundCorner(radius: CGFloat, _ node: SKSpriteNode, topLeft: Bool = true, topRight: Bool = true, bottomLeft: Bool = true, bottomRight: Bool = true) -> Void {
        guard let parent = node.parent else { return }
        let newNode = SKShapeNode(rectOf: node.size)
        newNode.fillColor = node.color
        newNode.lineWidth = 0
        newNode.position = node.position
        newNode.name = node.name
        node.removeFromParent()
        parent.addChild(newNode)
        var corners = UIRectCorner()
        if topLeft { corners = corners.union(.bottomLeft) }
        if topRight { corners = corners.union(.bottomRight) }
        if bottomLeft { corners = corners.union(.topLeft) }
        if bottomRight { corners = corners.union(.topRight) }
        newNode.path = UIBezierPath(roundedRect: CGRect(x: -(newNode.frame.width / 2), y: -(newNode.frame.height / 2), width: newNode.frame.width, height: newNode.frame.height), byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius)).cgPath
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
        } else if nowLevelNum < 100 {
            levelNumLabel.fontSize = 384
            levelNumLabel.position = CGPoint(x: screenWidth / 2, y: 250)
        } else if nowLevelNum < 1000 {
            levelNumLabel.fontSize = 248
            levelNumLabel.position = CGPoint(x: screenWidth / 2, y: 284)
        }
        state = .ready
        pastTime = 0
        pastTimeStart = 0
        pastStaticTime = 0
        staticTime = 0
        touched = false
        multiTouching = false
        ballNode.isHidden = false
        ballNode.physicsBody?.angularVelocity = 0
        ballNode.physicsBody?.isDynamic = true
        ballNode.physicsBody?.affectedByGravity = false
        ballNode.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        ballNode.zRotation = 0
        objNodeIndex.removeAll()
        objNodeIndex["ball"] = 0
        nowNode = ballNode
        nowNodeIndex = 0
        stateBar.alpha = 0
        stateBar.zPosition = 12
        stateBar.isHidden = true
        rotationNode.alpha = 0
        functionNode.alpha = 0
 
        timeLabel.text = "0.000"
        bestTime = defaults.double(forKey: "best\(nowLevelNum)")
        if bestTime == 0 { bestTime = 10 }
        objNodes = levelNode.childNode(withName: "//objNodes")
        startNode = levelNode.childNode(withName: "//start") as! SKSpriteNode
        endNode = levelNode.childNode(withName: "//end") as! SKSpriteNode

        obstacleLayer = levelNode.childNode(withName: "//obstacleLayer")
        obstacleLayer?.removeFromParent()
        tutorialLayer = levelNode.childNode(withName: "//tutorialLayer")
        tutorialLayerBg = tutorialLayer?.childNode(withName: "tutorialBg") as? SKSpriteNode
        countObjNodeIndex()
        level.checkTimeScore()

        nowNode.position = startNode.position // init position
        lastTouchLocation = ballNode.position
        lastTouchNodeLocation = ballNode.position
                
        passedLevelNum = 0
        totalTime = defaults.double(forKey: "totalTime")
        
        levelTutorial = levelTutorialStates
        initTutorial() // make a tutorial if necessary
        
        if let movingBlock = levelNode.childNode(withName: "//movingBlock") as? SKSpriteNode {
            var dis = 200
            var tmL: SKActionTimingMode = SKActionTimingMode.linear
            var tmR: SKActionTimingMode = SKActionTimingMode.linear
            switch nowLevelNum {
            case 11:
                tmL = SKActionTimingMode.easeInEaseOut
            case 34:
                tmR = SKActionTimingMode.easeInEaseOut
            default:
                break
            }
            var mLeft = SKAction.move(by: CGVector(dx: dis, dy: 0), duration: 1.5)
            var mRight = SKAction.move(by: CGVector(dx: -dis, dy: 0), duration: 1.5)
            var mLR = SKAction.sequence([mLeft, mRight])
            let action = SKAction.repeatForever(mLR)
            mLeft.timingMode = tmL
            mRight.timingMode = tmR
            movingBlock.run(action)
            
            if let mB2 = levelNode.childNode(withName: "//movingBlock2") as? SKSpriteNode {
                dis = 292
                mLeft = SKAction.move(by: CGVector(dx: dis, dy: 0), duration: 0.96)
                mRight = SKAction.move(by: CGVector(dx: -dis, dy: 0), duration: 0.96)
                mRight.timingMode = SKActionTimingMode.easeIn
                mLeft.timingMode = SKActionTimingMode.easeOut
                mLR = SKAction.sequence([mLeft, mRight])
                mB2.run(SKAction.repeatForever(mLR))
            }
        }
    }
    
    func countObjNodeIndex() -> Void {
        for (n, obj) in objNodes.children.enumerated() {
            let name = obj.name!
            let zr = obj.zRotation
            let pos = obj.position
            let zero = CGPoint(x: 0, y: 0)
            objNodeIndex[name] = n + 1
            if obj.position != zero {
                obj.position = zero
                obj.children.first!.children.first!.position = pos
                obj.zRotation = 0
                obj.children.first!.children.first!.zRotation = zr
                if name == "shortStickM" {
                    let stick = obj.children.first!.children.first!.children.first as! ShortStick
                    if zr > 1 {
                        stick.direction = stick.left
                    } else if zr == 0 {
                        stick.direction = stick.right
                    }
                }
            }
        }
    }
    
    func initTutorial() -> Void {
        if let tutorial = self.tutorialLayer {
            popLastTutorialState()
            
            for node in tutorial.children { node.alpha = 0 }
            
            tutorialLayerBg!.removeAllActions()
            tutorialLayerBg!.zPosition = 0
            if tutorialState != .done {
                tutorialLayerBg!.run(SKAction.afterDelay(0.4, performAction: SKAction.fadeIn(withDuration: 0.48)))
            }
            
            if let skip = childNode(withName: "//skipLabelArea") as? MSButtonNode {
                skip.selectedHandler = {
                    self.childNode(withName: "//tutorialMovingLabel")?.removeFromParent()
                    self.childNode(withName: "//tutorialMovingLabel2")?.removeFromParent()
                    skip.parent!.run(SKAction.fadeOut(withDuration: 0.24))
                    self.tutorialLayer?.isHidden = true
                    self.tutorialLayer?.removeFromParent()
                    self.levelTutorial[self.nowLevelNum] = []
                    self.tutorialState = .done
                }
            }
        } else {
            tutorialState = .done
        }
    }
    
    func buttonGoSelector() -> Void {
        self.objState.objPos[self.ballNode.name!] = self.ballNode.position
        self.ballNode.physicsBody?.affectedByGravity = true
        self.state = .dropping
        self.nowNode = self.ballNode
        self.nowNodeIndex = 0
        if let obstacleLayer = self.obstacleLayer {
            self.levelNode.addChild(obstacleLayer)
            obstacleLayer.alpha = 0
        }
    }
    
    func buttonObjIconSelector() -> Void {
        if self.nowNodeIndex == self.objNodes.children.count {
            self.nowNodeIndex = 0
            self.nowNode = self.ballNode
        } else {
            self.nowNode = self.objNodes.children[self.nowNodeIndex].children.first!.children.first!
        }
        self.nowNode.run(SKAction(named: "scaleToFocus")!)
    }

    func passedAllLevels() -> Void {
        defaults.set(true, forKey: "passedAll")
        defaults.synchronize()
        let skView = self.view as SKView!
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView?.ignoresSiblingOrder = true
        level.fromGameScenePassedAll = true
        skView?.presentScene(level)
    }
    
    func bestTimeScore() -> Void {
        if pastTime > 0 && Double(pastTime) < bestTime && bestTime != 10 || bestTime == 10 {
            totalTime -= bestTime
            bestTime = Double(pastTime)
            totalTime += bestTime
            totalTime = totalTime < 0 ? 0 : totalTime
            defaults.set(totalTime, forKey: "totalTime")
        }
        defaults.set(bestTime, forKey: "best\(nowLevelNum)")
        defaults.synchronize()
        saveScoreToGC()
    }
    
    func angleToRadian(_ angle: CGFloat) -> CGFloat {
        return pai * angle / 180.0
    }
    
    func radianToAngle(_ radian: CGFloat) -> CGFloat {
        return (radian * 180.0 / pai).truncatingRemainder(dividingBy: 360)
    }
    
    func updateRF() -> Void {
        
        var name = nowNode.parent?.parent?.name
        if nowNode == ballNode { name = "ball" }
        if objs[name!] == nil { return }
        
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
                if pos.x > 0 && pos.x < screenWidth && pos.y > menuHeight && pos.y < screenHeight {
                    // inside screen
                    if pos.x > c && pos.x < screenWidth - c && pos.y > c && pos.y < screenHeight - c / 2 {
                        // centre
                        rPos.x += d
                        fPos.x += -d
                    } else if pos.x <= screenWidth / 2 && pos.y <= screenHeight / 2 {
                        // bottom left
                        rPos.x += d
                        rPos.y += d / 3
                        fPos.x += d / 3
                        fPos.y += d
                    } else if pos.x >= screenWidth / 2 && pos.y <= screenHeight / 2 {
                        // bottom right
                        rPos.x += -d
                        rPos.y += d / 3
                        fPos.x += -d / 3
                        fPos.y += d
                    } else if pos.x <= screenWidth / 2 && pos.y >= screenHeight / 2 {
                        // top left
                        rPos.x += d
                        rPos.y += -d / 3
                        fPos.x += d / 3
                        fPos.y += -d
                    } else if pos.x >= screenWidth / 2 && pos.y >= screenHeight / 2 {
                        // top right
                        rPos.x += -d
                        rPos.y += -d / 3
                        fPos.x += -d / 3
                        fPos.y += -d
                    }
                } else if pos.y > menuHeight && pos.y < screenHeight {
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
                    } else if pos.y > screenHeight - d {
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
                    } else if pos.y >= screenHeight {
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
                    if pos.y > screenHeight - c {
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
                } else if pos.y > screenHeight / 2 {
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
                rotationNode.run(SKAction(named: "fadeIn")!)
            }
            if f {
                functionNode.run(SKAction(named: "fadeIn")!)
            }
            
        }
    }
    
    func checkStateBar() -> Void {
        if stateBar.alpha != 0 {
            stateBar.run(SKAction(named: "fadeOutHide")!)
        }
        stateBar.removeAllChildren()
    }
    
    func updateObjMove(_ location: CGPoint) -> Void {
        var pos = location + lastTouchNodeLocation - lastTouchLocation
        if nowNode == ballNode {
            // ball hit wall cases
            if pos.x <= ballRadius || pos.x >= screenWidth - ballRadius ||
                pos.y >= screenHeight - ballRadius || pos.y <= menuHeight + ballRadius {
                
                lastTouchNodeLocation = nowNode.position
                pos = location + lastTouchNodeLocation - lastTouchLocation
                lastTouchLocation = location
                
                // preventing first hitwall the ball position will change a lot by lastTouchLocation's big change
                if !ballMovingHitWall {
                    pos = ballNode.position
                }
                
                pos.x = pos.x <= ballRadius ? ballRadius : pos.x
                pos.x = pos.x >= screenWidth - ballRadius ? screenWidth - ballRadius : pos.x
                pos.y = pos.y >= screenHeight - ballRadius ? screenHeight - ballRadius : pos.y
                pos.y = pos.y <= menuHeight + ballRadius ? menuHeight + ballRadius : pos.y
                ballMovingHitWall = true
            } else {
                ballMovingHitWall = false
            }
        }
        nowNode.position = pos
    }
    
    func objFunctionMoving(_ location: CGPoint) -> Void {
        let dy = location.y - functionNode.position.y
        let dx = location.x - functionNode.position.x
        for child in nowNode.children {
            if let bm = child.physicsBody?.categoryBitMask {
                if bm < 0 || bm == 4294967295 { continue }
                switch Int(bm) {
                case 2:
                    if let bounce = child as? Bounce {
                        if bounce.k < bounce.kMax && dy > 0 || bounce.k > bounce.kMin && dy < 0 {
                            bounce.k += dy / 200
                        }
                        var a = bounceFunctionV1!.dy / abs(bounceFunctionV1!.dy)
                        let b1 = stateBar.childNode(withName: "smallBall1")!.physicsBody
                        let b2 = stateBar.childNode(withName: "smallBall2")!.physicsBody
                        let bar = stateBar.childNode(withName: "bounceBar") as! SKSpriteNode
                        bar.size.width = bounce.k / bounce.kMax * screenWidth
                        if bounceFunctionV1!.dy == 0 { a = 1 }
                        bounceFunctionV1 = CGVector(dx: 0, dy: a * bounce.k * 300)
                        a = bounceFunctionV2!.dy / abs(bounceFunctionV2!.dy)
                        if bounceFunctionV2!.dy == 0 { a = -1 }
                        bounceFunctionV2 = CGVector(dx: 0, dy: a * bounce.k * 300)
                        b1?.velocity = bounceFunctionV1!
                        b2?.velocity = bounceFunctionV2!
                    }
                case 4:
                    if let shortStick = child as? ShortStick {
                        let b = stateBar.childNode(withName: "smallBall")!.physicsBody
                        if shortStick.direction != "left" && dx < 0 {
                            shortStick.direction = "left"
                            b?.velocity = CGVector(dx: 0, dy: 0)
                            b?.applyImpulse(CGVector(dx: -5, dy: 0))
                            nowNode.run(SKAction.rotate(toAngle: angleToRadian(60), duration: 0.21))
                        } else if shortStick.direction != "right" && dx > 0 {
                            shortStick.direction = "right"
                            b?.velocity = CGVector(dx: 0, dy: 0)
                            b?.applyImpulse(CGVector(dx: 5, dy: 0))
                            nowNode.run(SKAction.rotate(toAngle: 0, duration: 0.21))
                        } else if shortStick.direction == "left" && dx < 0
                            || shortStick.direction == "right" && dx > 0 {
                            b?.velocity += CGVector(dx: dx * 2, dy: 0)
                        }
                    }
                case 8:
                    if let stick = child as? Stick {
                        if stick.xScale < stick.lenMax && dy > 0 || stick.xScale > stick.lenMin && dy < 0 {
                            stick.xScale += dy / 100
                        }
                        let x = stick.xScale
                        stick.xScale = x > 2 ? 2 : x < 0.5 ? 0.5 : x
                        let bar = stateBar.childNode(withName: "stickBar") as! SKSpriteNode
                        bar.xScale = stick.xScale
                    }
                default:
                    break
                }
            }
        }
    }
    
    func objFunctionBegan() -> Void {
        stateBar.run(SKAction(named: "fadeInHide")!)
        
        for child in nowNode.children {
            if let bm = child.physicsBody?.categoryBitMask {
                switch Int(bm) {
                case 2:
                    if let bounce = child as? Bounce {
                        let bounceBar = SKSpriteNode(color: UIColor.white, size: CGSize(width: screenWidth * bounce.k / bounce.kMax, height: menuHeight))
                        bounceBar.name = "bounceBar"
                        bounceBar.alpha = 0.4
                        let smallBall = SKSpriteNode(imageNamed: "ballIcon")
                        let groundTop = SKShapeNode(rectOf: CGSize(width: screenWidth, height: 2))
                        let groundBottom = SKShapeNode(rectOf: CGSize(width: screenWidth, height: 2))
                        groundTop.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: screenWidth, height: 2))
                        groundBottom.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: screenWidth, height: 2))
                        smallBall.physicsBody = SKPhysicsBody(circleOfRadius: smallBall.size.width / 2)
                        groundTop.physicsBody?.isDynamic = false
                        groundBottom.physicsBody?.isDynamic = false
                        groundBottom.physicsBody?.contactTestBitMask = 1
                        groundTop.physicsBody?.contactTestBitMask = 1
                        groundTop.physicsBody?.categoryBitMask = 5
                        groundBottom.physicsBody?.categoryBitMask = 5
                        smallBall.physicsBody?.isDynamic = true
                        smallBall.physicsBody?.affectedByGravity = false
                        smallBall.physicsBody?.allowsRotation = true
                        bounceFunctionV1 = CGVector(dx: 0, dy: bounce.k * 300)
                        bounceFunctionV2 = CGVector(dx: 0, dy: -bounce.k * 300)
                        smallBall.physicsBody?.velocity = bounceFunctionV1!
                        groundBottom.position = CGPoint(x: 0, y: -33.5)
                        groundTop.position = CGPoint(x: 0, y: 33.5)
                        groundTop.alpha = 0
                        groundBottom.alpha = 0
                        smallBall.name = "smallBall1"
                        smallBall.position = CGPoint(x: -84, y: smallBall.position.y)
                        let b2 = smallBall.copy() as! SKSpriteNode
                        b2.name = "smallBall2"
                        b2.physicsBody?.velocity = bounceFunctionV2!
                        b2.position = CGPoint(x: 84, y: b2.position.y)
                        stateBar.addChild(groundTop)
                        stateBar.addChild(groundBottom)
                        stateBar.addChild(smallBall)
                        stateBar.addChild(b2)
                        stateBar.addChild(bounceBar)
                        return
                    }
                case 4:
                    if let shortStick = child as? ShortStick {
                        let smallBall = SKSpriteNode(imageNamed: "ballIcon")
                        let ground = SKShapeNode(rectOf: CGSize(width: screenWidth, height: 3))
                        smallBall.name = "smallBall"
                        smallBall.physicsBody = SKPhysicsBody(circleOfRadius: smallBall.size.width / 2)
                        smallBall.physicsBody?.isDynamic = true
                        smallBall.physicsBody?.affectedByGravity = true
                        smallBall.physicsBody?.allowsRotation = true
                        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: screenWidth, height: 3))
                        ground.physicsBody?.isDynamic = false
                        ground.alpha = 0
                        stateBar.addChild(ground)
                        stateBar.addChild(smallBall)
                        ground.position = CGPoint(x: 0, y: -20)
                        
                        if shortStick.direction == "right" {
                            smallBall.physicsBody?.applyImpulse(CGVector(dx: 4, dy: 0))
                        } else if shortStick.direction == "left" {
                            smallBall.physicsBody?.applyImpulse(CGVector(dx: -4, dy: 0))
                        }
                        return
                    }
                case 8:
                    if let stick = child as? Stick {
                        let stickBar = SKSpriteNode(color: UIColor.white, size: CGSize(width: screenWidth / 2, height: menuHeight))
                        stickBar.name = "stickBar"
                        stickBar.alpha = 0.4
                        stickBar.xScale = stick.xScale
                        stickBar.anchorPoint = CGPoint(x: 0, y: 0)
                        stickBar.position = CGPoint(x: -screenWidth / 2, y: -menuHeight / 2)
                        stateBar.addChild(stickBar)
                        return
                    }
                default:
                    break
                }
            }
        }
    }
    
    // no use just for test
    func noOverlap() -> Bool {
        let objs = objNodes.children
        for (i, obj) in objs.enumerated() {
            for j in (i + 1) ..< objs.count {
                let objA = obj.children.first!.children.first!
                let objB = objs[j].children.first!.children.first!
                for a in objA.children {
                    for b in objB.children {
                        if a.intersects(b) {
                            return false
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    func saveObjsState() -> Void {
        for obj in objNodes.children {
            let name = obj.name!
            let node = obj.children.first!.children.first!
            objState.objPos[name] = node.position
            objState.objClass[name] = node
        }
    }
    
    func reloadObjsState() -> Void {
        if objState.levelNum != nowLevelNum { return }
        
        ballNode.position = objState.objPos[ballNode.name!]!
        
        for obj in objNodes.children {
            let name = obj.name!
            if let objNode = objState.objClass[name] {
                let node = obj.children.first!.children.first!
                let child = objNode.children.first!
                obj.children.first!.children.first!.position = objState.objPos[name]!
                obj.children.first!.children.first!.zRotation = objNode.zRotation
                if let bm = child.physicsBody?.categoryBitMask {
                    switch Int(bm) {
                    case 2:
                        if let bounce = child as? Bounce {
                            for nodeChild in node.children {
                                if let t = nodeChild as? Bounce {
                                    t.k = bounce.k
                                }
                            }
                        }
                    case 4:
                        if let shortStick = child as? ShortStick {
                            let t = node.children.first! as! ShortStick
                            t.direction = shortStick.direction
                        }
                    case 8:
                        if let stick = child as? Stick {
                            let t = node.children.first! as! Stick
                            t.xScale = stick.xScale
                        }
                    case 16:
                        break // bounceI
                    default:
                        break
                    }
                }
            }
        }
    }
    
    // no use
    func loadLevelN(_ n: Int) -> Void {
        if levelNode.children.count == 0 {
            let levelPath = Bundle.main.path(forResource: "Level\(n)", ofType: "sks")
            let newLevel = SKReferenceNode(url: URL(fileURLWithPath: levelPath!))
            newLevel.name = "level\(n)"
            nowLevelNum = n
            levelNode.addChild(newLevel)
        }
    }

    func tutorialTouchMoving(_ pos: CGPoint) -> Void {
//        if let path = NSBundle.mainBundle().pathForResource("TouchIcon", ofType: "sks") {
            var ly: CGFloat = 484
            if nowLevelNum == 2 {
                ly = 108
            }
            
            let label = SKLabelNode(text: "Hold the blank and move")
            levelNode.addChild(label)
            label.name = "tutorialMovingLabel"
            label.position = CGPoint(x: 187.5, y: ly)
            label.zPosition = 50
            label.fontSize = 23
            let bg = SKShapeNode.init(rect: CGRect(origin: CGPoint(x: -151, y: -14), size: CGSize(width: 302, height: 48)), cornerRadius: 8.4)
            bg.fillColor = UIColor.black
            bg.strokeColor = UIColor.black
            bg.alpha = 0.32
            label.addChild(bg)
    }
    
    func introIconActions() -> Void {
        let label = SKLabelNode(text: "Then the current object is")
        levelNode.addChild(label)
        label.name = "tutorialHelp"
        label.position = CGPoint(x: 0, y: 148) + nowNode.position
        label.zPosition = 50
        label.fontSize = 17
        
        let label2 = SKLabelNode(text: "Short Stick")
        let label3 = SKLabelNode(text: "As you can see the small icon below")
        let label4 = SKLabelNode(text: "Now tap to continue to move it ...")
        label2.position = CGPoint(x: 0, y: -24)
        label2.fontSize = 18
        label3.position = CGPoint(x: 0, y: -48)
        label3.fontSize = 17
        label4.position = CGPoint(x: 0, y: -72)
        label4.fontSize = 17
        
        label.addChild(label2)
        label.addChild(label3)
        label.addChild(label4)
        
        label.alpha = 0
        label.run(SKAction.afterDelay(0.1, performAction: SKAction.fadeIn(withDuration: 0.4)))
        
        let bg = SKShapeNode.init(rect: CGRect(origin: CGPoint(x: -142, y: -92.8), size: CGSize(width: 284, height: 128)), cornerRadius: 8.4)
        bg.fillColor = UIColor.black
        bg.strokeColor = UIColor.black
        bg.alpha = 0.32
        label.addChild(bg)
    }
    
    func introStartLabelActions() -> Void {
        let arrowStart = tutorialLayer!.childNode(withName: "arrowStart")
        let labelStart = tutorialLayer!.childNode(withName: "labelStart")
        
        let fadeInDelay = SKAction.afterDelay(0.32, performAction: SKAction.fadeIn(withDuration: 0.23))
        arrowStart?.run(fadeInDelay)
        labelStart?.run(fadeInDelay)
    }
    
    func introGoalLabelActions() -> Void {
        let arrowStart = tutorialLayer!.childNode(withName: "arrowStart")
        let labelStart = tutorialLayer!.childNode(withName: "labelStart")
        let arrowGoal = tutorialLayer!.childNode(withName: "arrowGoal")
        let labelGoal = tutorialLayer!.childNode(withName: "labelGoal")
        
        let hide = SKAction.hide()
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        let actOut = SKAction.sequence([fadeOut, hide])
        let fadeIn = SKAction.fadeIn(withDuration: 0.8)
        arrowStart?.run(actOut)
        labelStart?.run(actOut)
        arrowGoal?.run(SKAction.afterDelay(0.1, performAction: fadeIn))
        labelGoal?.run(SKAction.afterDelay(0.1, performAction: fadeIn))
    }
    
    func tutorialGo() -> Void {
        childNode(withName: "//tutorialMovingLabel")?.removeFromParent()
        childNode(withName: "//tutorialMovingLabel2")?.removeFromParent()

        tutorialLayerBg?.run(SKAction.fadeIn(withDuration: 0.23))
        
        let btnGo = buttonGo.copy() as! MSButtonNode
        levelNode.addChild(btnGo)
        btnGo.name = "tutorialHelp"
        btnGo.alpha = 0
        btnGo.position = buttonGo.position + menuNode.position
        btnGo.xScale = buttonGo.xScale
        btnGo.yScale = buttonGo.yScale
        btnGo.zPosition = 50
        btnGo.run(SKAction(named: "scaleToTouch1")!)
        btnGo.selectedHandler = {
            self.tutorialLayerBg!.run(SKAction.fadeOut(withDuration: 0.32))
            self.buttonGoSelector()
            self.popLastTutorialState()
        }
    }
    
    func tutorialIcon() -> Void {
        if nowLevelNum == 1 {
            let arrowGoal = tutorialLayer!.childNode(withName: "arrowGoal")
            let labelGoal = tutorialLayer!.childNode(withName: "labelGoal")
            let hide = SKAction.hide()
            let fadeOut = SKAction.fadeOut(withDuration: 0.8)
            let actOut = SKAction.sequence([fadeOut, hide])
            arrowGoal?.run(actOut)
            labelGoal?.run(actOut)
        }
        
        if tutorialLayerBg?.alpha == 0 {
            tutorialLayerBg?.run(SKAction.fadeIn(withDuration: 0.27))
        }
        
        let label = SKLabelNode(text: "Tap to change current object")
        menuNode.addChild(label)
        label.name = "tutorialHelp"
        label.position = CGPoint(x: 0, y: 57) + objIconNode.position
        label.zPosition = 50
        label.fontSize = 17
        
        let arrow = SKSpriteNode(texture: SKTextureAtlas(named: "assets").textureNamed("arrowIcon"))
        label.addChild(arrow)
        arrow.position -= CGPoint(x: 0, y: 22)
        arrow.zRotation = angleToRadian(180)
        arrow.zPosition = 50
        
        let objIcon = objIconNode.copy() as! MSButtonNode
        label.addChild(objIcon)
        objIcon.alpha = 0
        objIcon.zPosition = 50
        objIcon.position = CGPoint(x: 0, y: -57)
        objIcon.run(SKAction(named: "scaleToTouch")!)
        objIcon.selectedHandler = {
            self.tutorialLayerBg!.run(SKAction.fadeOut(withDuration: 0.32))
            self.buttonObjIconSelector()
            self.popLastTutorialState()
        }
        
        label.alpha = 0
        label.run(SKAction.afterDelay(0.23, performAction: SKAction.fadeIn(withDuration: 0.4)))
    }
    
    func popLastTutorialState() -> Void {
        if let ts = levelTutorial[nowLevelNum]?.popLast() {
            tutorialState = ts
        } else {
            tutorialState = .done
        }
    }

    // no use
    func nowNodeFadeIn(_ x: CGFloat) -> Void {
        if nowNode != ballNode {
            nowNode.removeAllActions()
            nowNode.position.x = x
            nowNode.run(SKAction.fadeIn(withDuration: 0.32))
        }
    }
    
    func tutorialBeforeIconLongPress() -> Void {
        let label = SKLabelNode(text: "Wait, where is my bounce???")
        levelNode.addChild(label)
        label.name = "tutorialHelp"
        label.position = CGPoint(x: screenWidth / 2, y: 248)
        label.zPosition = 50
        label.fontSize = 21
        let bg = SKShapeNode(rect: CGRect(origin: CGPoint(x: -156, y: -18),
            size: CGSize(width: 312, height: 52)), cornerRadius: 8.4)
        bg.fillColor = UIColor.black
        bg.strokeColor = UIColor.black
        bg.alpha = 0.32
        label.addChild(bg)
        label.alpha = 0
        label.run(SKAction.afterDelay(0.2, performAction: SKAction.fadeIn(withDuration: 0.2)))
    }
    
    func tutorialIconLongPress() -> Void {
        tutorialLayerBg!.run(SKAction.fadeIn(withDuration: 0.28))
        
        let label = SKLabelNode(text: "Long press the icon")
        menuNode.addChild(label)
        label.name = "tutorialHelp"
        label.position = CGPoint(x: 0, y: 57) + objIconNode.position
        label.zPosition = 50
        label.fontSize = 17
        
        let arrow = SKSpriteNode(texture: SKTextureAtlas(named: "assets").textureNamed("arrowIcon"))
        label.addChild(arrow)
        arrow.position -= CGPoint(x: 0, y: 25)
        arrow.zRotation = angleToRadian(180)
        arrow.zPosition = 50
        
        let objIcon = objIconNode.copy() as! MSButtonNode
        label.addChild(objIcon)
        objIcon.name = "tutorialIconLongPress"
        objIcon.alpha = 0
        objIcon.zPosition = 50
        objIcon.position = CGPoint(x: 0, y: -57)
        objIcon.run(SKAction(named: "scaleToTouch")!)
        
    }
    
    func tutorialIconLongPressNext() -> Void {
        let label = SKLabelNode(text: "Cool, here it is~")
        levelNode.addChild(label)
        label.name = "tutorialHelp"
        label.position = CGPoint(x: screenWidth / 2, y: 248)
        label.zPosition = 50
        label.fontSize = 21
        let bg = SKShapeNode.init(rect: CGRect(origin: CGPoint(x: -156, y: -18), size: CGSize(width: 312, height: 52)), cornerRadius: 8.4)
        bg.fillColor = UIColor.black
        bg.strokeColor = UIColor.black
        bg.alpha = 0.32
        label.addChild(bg)
        label.alpha = 0
        label.run(SKAction.afterDelay(0.84, performAction: SKAction.fadeIn(withDuration: 0.2)))
    }
    
    func tutorialFunctionIcon() -> Void {
        var mainText = "This is button Y"
        var funcText = "Try to drag it to rightside"
        var w = 214
        var alpha: CGFloat = 0.78
        var pos = functionNode.position
        
        if nowLevelNum == 3 {
            mainText = "This is button Y of bounce"
            funcText = "Drag up and down to change force"
            w = 300
            alpha = 0.32
            pos = CGPoint(x: 214, y: 384)
        }

        let label = SKLabelNode(text: mainText)
        levelNode.addChild(label)
        label.name = "tutorialHelp"
        label.position = CGPoint(x: 0, y: -94) + pos
        label.zPosition = 50
        label.fontSize = 21
        let bg = SKShapeNode.init(rect: CGRect(origin: CGPoint(x: -w / 2, y: -50), size: CGSize(width: w, height: 84)), cornerRadius: 8.4)
        bg.fillColor = UIColor.black
        bg.strokeColor = UIColor.black
        bg.alpha = alpha
        label.addChild(bg)
        let label2 = SKLabelNode(text: funcText)
        label2.position = CGPoint(x: 0, y: -31)
        label2.zPosition = 50
        label2.fontSize = 20
        label.addChild(label2)
        
        let arrow = SKSpriteNode(texture: SKTextureAtlas(named: "assets").textureNamed("arrowIcon"))
        label.addChild(arrow)
        arrow.position -= CGPoint(x: 0, y: -60)
        arrow.zPosition = 50
        
        label.alpha = 0
        label.run(SKAction.afterDelay(0.23, performAction: SKAction.fadeIn(withDuration: 0.4)))
    }
    
    func tutorialStateBar() -> Void {
        childNode(withName: "//tutorialHelp")?.run(SKAction.fadeOut(withDuration: 0.23))
        
        let label = SKLabelNode(text: "State bar will be shown here")
        if nowLevelNum == 3 {
            label.text = "Modifying force of the bounce"
        }
        levelNode.addChild(label)
        label.name = "tutorialState"
        label.position = CGPoint(x: screenWidth / 2, y: 125)
        label.zPosition = 50
        label.fontSize = 21
        let bg = SKShapeNode.init(rect: CGRect(origin: CGPoint(x: -142, y: -17), size: CGSize(width: 284, height: 51)), cornerRadius: 8.4)
        bg.fillColor = UIColor.black
        bg.strokeColor = UIColor.black
        bg.alpha = 0.32
        label.addChild(bg)
        
        let arrow = SKSpriteNode(texture: SKTextureAtlas(named: "assets").textureNamed("arrowIcon"))
        label.addChild(arrow)
        arrow.position -= CGPoint(x: 0, y: 39)
        arrow.zRotation = angleToRadian(180)
        arrow.zPosition = 50
    }
    
    func tutorialFunctionNext() -> Void {
        let y: CGFloat = nowLevelNum == 2 ? 184 : 248
        let label = SKLabelNode(text: "Now it's your time!")
        levelNode.addChild(label)
        label.name = "tutorialHelpEnd"
        label.position = CGPoint(x: screenWidth / 2, y: y)
        label.zPosition = 50
        label.fontSize = 27
        let bg = SKShapeNode.init(rect: CGRect(origin: CGPoint(x: -156, y: -19), size: CGSize(width: 312, height: 61)), cornerRadius: 8.4)
        bg.fillColor = UIColor.black
        bg.strokeColor = UIColor.black
        bg.alpha = 0.36
        label.addChild(bg)
        
        label.alpha = 0
        label.run(SKAction.afterDelay(0.777, performAction: SKAction.fadeIn(withDuration: 0.4)))
    }
    
    func tutorialTapBounce() -> Void {
        if let bounce = childNode(withName: "//bounceRF") {
            let pos = bounce.children.first!.children.first!.position
            
            let label = SKLabelNode(text: "Tap the bounce")
            levelNode.addChild(label)
            label.name = "tutorialHelp"
            label.position = pos + CGPoint(x: 0, y: -72)
            label.zPosition = 50
            label.fontSize = 21

            let arrow = SKSpriteNode(texture: SKTextureAtlas(named: "assets").textureNamed("arrowIcon"))
            label.addChild(arrow)
            arrow.position -= CGPoint(x: 0, y: -41)
            arrow.zPosition = 50
            
            label.alpha = 0
            label.run(SKAction.afterDelay(0.24, performAction: SKAction.fadeIn(withDuration: 0.4)))
            
            let b = bounce.copy() as! SKNode
            label.addChild(b)
            b.position = CGPoint(x: 0, y: 72)
            let scaleLarge = SKAction.scale(to: 1.24, duration: 0.48)
            let scale = SKAction.scale(to: 1, duration: 0.36)
            let delay = SKAction.wait(forDuration: 1.24)
            let action = SKAction.sequence([scale, delay, scaleLarge])
            scaleLarge.timingMode = SKActionTimingMode.easeInEaseOut
            scale.timingMode = SKActionTimingMode.easeInEaseOut
            b.run(SKAction.repeatForever(action))
            
        }
    }
    
    func passedLevelNumCount() -> Void {
        passedLevelNum = 0
        for n in 1...levelNum {
            if defaults.double(forKey: "best\(n)") < 10 {
                passedLevelNum += 1
            }
        }
    }

    func saveScoreToGC() -> Void {
        if GKLocalPlayer.localPlayer().isAuthenticated {
            let scoreReporter = GKScore(leaderboardIdentifier: "level\(nowLevelNum)")
            scoreReporter.value = Int64(bestTime * 1000 + 0.5)
            
            let scoreArray: [GKScore] = [scoreReporter]
            
            GKScore.report(scoreArray, withCompletionHandler: nil)
            
            let scoreReporterTotal = GKScore(leaderboardIdentifier: gcWorld)
            scoreReporterTotal.value = Int64(totalTime * 1000 + 0.5)
            
            let scoreArrayTotal: [GKScore] = [scoreReporterTotal]
            
            GKScore.report(scoreArrayTotal, withCompletionHandler: nil)
        }
    }
    
    func showLeaderBoard() -> Void {
        let viewController = self.view!.window?.rootViewController
        let gcvc = GKGameCenterViewController()
        gcvc.leaderboardIdentifier = "level\(nowLevelNum)"
        gcvc.gameCenterDelegate = self
        viewController?.present(gcvc, animated: true, completion: nil)
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
}
