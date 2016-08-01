//
//  GameScene.swift
//  Don't Drop Me!
//
//  Created by 高宇超 on 7/5/16.
//  Copyright (c) 2016 Yuchao. All rights reserved.
//

import SpriteKit

enum GameState {
    case Ready, Dropping, Pass, Failed, GameOverPass, GameOverFailed
}

enum TutorialState {
    case Done,
    Go, IntroStart, IntroGoal, Icon, IntroIcon, TouchMoving,
    IconLongPress, BeforeIconLongPress, IconLongPressNext, Function, FNext,
    TapBounce
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
    
    var level: Level!
    var home: Home!
    
    var ballNode: Ball!
    var levelNode: SKNode!
    var startNode: SKSpriteNode! {
        didSet {
            cropRoundCorner(startNode)
        }
    }
    var endNode: SKSpriteNode! {
        didSet {
            cropRoundCorner(endNode)
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
    var resultLabel: SKLabelNode!
    var objNameLabel: SKLabelNode!
    var objIconNode: MSButtonNode!
    var objNodes: SKNode!
    var levelNumLabel: SKLabelNode!
    var rotationNode: SKSpriteNode!
    var functionNode: SKSpriteNode!
    var obstacleLayer: SKNode?
    var stateBar: SKSpriteNode!
    var tutorialLayer: SKNode?
    var tutorialLayerBg: SKSpriteNode?
    var scoreBoard: SKSpriteNode!
    
    var defaults: NSUserDefaults!
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
    var objIconTouchBeganTime: NSTimeInterval!
    var longPressObjIconUpdateRF = false
    
    var bounceFunctionV1: CGVector?
    var bounceFunctionV2: CGVector?
    
    var objState: ObjState!

    var levelTutorial: [Int: [TutorialState]]!
    let levelTutorialStates: [Int: [TutorialState]] = [
        1: [.Done, .Go, .TouchMoving, .IntroIcon, .Icon, .IntroGoal, .IntroStart],
        2: [.Done, .FNext, .Function, .Icon, .IconLongPressNext, .IconLongPress, .BeforeIconLongPress, .Icon],
        3: [.Done, .FNext, .Function, .TapBounce],
    ]
    
    var tutorialState: TutorialState = .Done {
        didSet {
            self.childNodeWithName("//tutorialHelp")?.removeFromParent()
            switch tutorialState {
            case .Go:
                tutorialGo()
            case .IntroStart:
                introStartLabelActions()
            case .IntroGoal:
                introGoalLabelActions()
            case .Icon:
                tutorialIcon()
            case .IntroIcon:
                introIconActions()
            case .TouchMoving:
                tutorialTouchMoving(CGPoint(x: screenWidth / 2, y: 250))
            case .BeforeIconLongPress:
                tutorialBeforeIconLongPress()
            case .IconLongPress:
                tutorialIconLongPress()
            case .IconLongPressNext:
                tutorialIconLongPressNext()
            case .Function:
                tutorialFunctionIcon()
            case .FNext:
                tutorialFunctionNext()
            case .TapBounce:
                tutorialTapBounce()
            case .Done:
                tutorialLayerBg?.runAction(SKAction.fadeOutWithDuration(0.23))
            }
        }
    }
    
    override func didMoveToView(view: SKView) {
        
        /* Setup your scene here */
        physicsWorld.contactDelegate = self
        
        enableMultiTouch()
        defaults = NSUserDefaults.standardUserDefaults()
        
        // node connection
        ballNode = self.childNodeWithName("ball") as! Ball
        levelNode = self.childNodeWithName("levelNode")
        menuNode = self.childNodeWithName("menu")!
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
        scoreBoard = self.childNodeWithName("scoreBoard") as! SKSpriteNode
        
        menuNode.childNodeWithName("menuBgd")!.alpha = 0.892
        
        levelTutorial = levelTutorialStates
        
        initGame()
        
        buttonHome.selectedHandler = {
            self.scoreBoardAndMenuMoveOut()
            self.levelNode.removeAllChildren()
            
            let skView = self.view as SKView!
            self.level.scaleMode = self.scaleMode
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            skView.presentScene(self.level, transition: SKTransition.doorwayWithDuration(0.8))
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
                    if self.tutorialState == .Done {
                        self.buttonGoSelector()
                    }
                }
            }
        }
        objIconNode.selectedHandler = {
            if self.state == .Ready {
                if self.tutorialState == .Done {
                    self.buttonObjIconSelector()
                }
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        if tutorialState == .TouchMoving {
            if touches.count == 1 {
                let touch = touches.first!
                lastTouchLocation = touch.locationInNode(self)
                let node = nodeAtPoint(lastTouchLocation)
                let label = childNodeWithName("//tutorialMovingLabel") as! SKLabelNode
                if node.name == "touchIn" {
                    label.text = "Drop the stick here"
                    let arrow = SKSpriteNode(texture: SKTexture(imageNamed: "arrowIcon"))
                    label.addChild(arrow)
                    arrow.name = "tutorialArrow"
                    arrow.position -= CGPoint(x: 98, y: 41)
                    arrow.zRotation = angleToRadian(180)
                    arrow.zPosition = 50
                    arrow.alpha = 0
                    arrow.runAction(SKAction.fadeInWithDuration(0.23))

                    let drop = SKShapeNode.init(rect: CGRect(origin: CGPoint(x: -40, y: -60), size: CGSize(width: 80, height: 120)), cornerRadius: 4.8)
                    drop.name = "tutorialDrop"
                    drop.fillColor = UIColor.blackColor()
                    drop.strokeColor = UIColor.blackColor()
                    drop.alpha = 0
                    drop.zPosition = -52
                    drop.position = CGPoint(x: -100, y: -124)
                    drop.runAction(SKAction.fadeAlphaTo(0.32, duration: 0.23))
                    label.addChild(drop)
                } else {
                    label.childNodeWithName("tutorialArrow")?.removeFromParent()
                    label.childNodeWithName("tutorialDrop")?.removeFromParent()
                }
            }
            return
        }
        if tutorialState != .Done && tutorialState != .Function {
            let p =
                tutorialState != .Icon &&
                tutorialState != .Go &&
                tutorialState != .IconLongPress &&
                tutorialState != .TapBounce
            if p {
                if tutorialState == .FNext {
                    levelNode.childNodeWithName("tutorialHelpEnd")?.runAction(SKAction.fadeOutWithDuration(0.23))
                    levelNode.childNodeWithName("tutorialHelpEnd")?.removeFromParent()
                }
                popLastTutorialState()
            }
            return
        } else if let help = childNodeWithName("//tutorialHelpEnd") {
            // if player taps too fast it will miss fade out actions
            help.runAction(SKAction.fadeOutWithDuration(0.23))
            help.removeFromParent()
            return
        }
        
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
                            if tutorialState == .Function { break }
                            functionNode.runAction(SKAction(named: "fadeOut")!)
                            startRotation = true
                            // fix bug that the rotation icon is not at the same y line as nowNode
                            let dy = nowNode.position.y - location.y
                            let dx = nowNode.position.x - location.x
                            startZR = nowNode.zRotation - atan2(dy, dx)
                        } else {
                            if tutorialState == .Function { tutorialStateBar() }
                            rotationNode.runAction(SKAction(named: "fadeOut")!)
                            startFunction = true
                            startPos = location
                            objFunctionBegan()
                        }
                    } else if tutorialState != .Function {
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
        if tutorialState != .Done && tutorialState != .Function {
            if tutorialState == .TouchMoving {
                if touches.count == 1 {
                    let touch = touches.first!
                    let pos = touch.locationInNode(self)
                    let label = childNodeWithName("//tutorialMovingLabel") as! SKLabelNode
                    if label.text == "Drop the stick here" {
                        updateObjMove(pos)
                        childNodeWithName("//tutorialHelp")?.position = pos
                    }
                }
            }
            return
        }

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
                        } else if tutorialState != .Function {
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
        
        if tutorialState != .Done && tutorialState != .Function {
            if tutorialState == .TouchMoving {
                if touches.count == 1 {
                    let touch = touches.first!
                    let pos = touch.locationInNode(self)
                    let node = nodeAtPoint(pos)
                    if node.name == "touchIn" {
                        lastTouchNodeLocation = nowNode.position
                        if let drop = childNodeWithName("//tutorialDrop") as? SKShapeNode {
                            let label = childNodeWithName("//tutorialMovingLabel") as! SKLabelNode
                            let w = drop.frame.width
                            let h = drop.frame.height
                            let p = drop.position + label.position
                            let np = nowNode.position
                            print("\(p) \(np)")
                            if abs(np.x - p.x) < w / 2 - 37 && abs(np.y - p.y) < h / 2 - 24 {
                                popLastTutorialState()
                                drop.runAction(SKAction.fadeOutWithDuration(0.21))
                            } else {
                                let label = childNodeWithName("//tutorialMovingLabel") as! SKLabelNode
                                label.text = "Hold to move current object"
                                label.childNodeWithName("tutorialArrow")?.removeFromParent()
                                label.childNodeWithName("tutorialDrop")?.removeFromParent()
                            }
                        } else {
                            let label = childNodeWithName("//tutorialMovingLabel") as! SKLabelNode
                            label.text = "Hold to move current object"
                            label.childNodeWithName("tutorialArrow")?.removeFromParent()
                            label.childNodeWithName("tutorialDrop")?.removeFromParent()
                        }
                    }
                }
            }
            return
        }

        let count = touches.count
        
        switch state {
        case .Ready:
            lastTouchNodeLocation = nowNode.position
            
            switch count {
            case 1:
                for touch in touches {
                    let location = touch.locationInNode(self)
                    let node = nodeAtPoint(location)
                    
                    checkStateBar()
                    
                    if let name = node.name {
                        print(name)
                        if tutorialState == .Function && (node == functionNode || node.parent == functionNode) {
                            levelNode.childNodeWithName("tutorialState")?.runAction(SKAction.fadeOutWithDuration(0.84))
                            popLastTutorialState()
                        }
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
                    if let nm = node.name {
                        if nm == "bg" || nm == "levelNumLabel" || nm == "scoreBoard" {
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
        if touches != nil && event != nil {
            touchesEnded(touches!, withEvent: event!)
        }
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
            if isBallInArea(startNode, hard: true) /*&& noOverlap()*/ {
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
            
            if longPressObjIconUpdateRF && nowNode.position == CGPoint(x: 187.5, y: 384) {
                updateRF()
                longPressObjIconUpdateRF =  false
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
        
        if state == .Dropping {
            
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
                nodeB.parent!.runAction(SKAction(named: "fadeHitObstacle")!)
            } else if categoryB == 1 && categoryA == 3 {
                nodeA.parent!.runAction(SKAction(named: "fadeHitObstacle")!)
            }
            
            // bounceI
            if categoryA == 1 && categoryB == 16 {
                let bounceNode = nodeB as! BounceI
                contactA.applyImpulse(contact.contactNormal * bounceNode.k)
            } else if categoryB == 1 && categoryA == 16 {
                let bounceNode = nodeA as! BounceI
                contactB.applyImpulse(contact.contactNormal * bounceNode.k)
            }
            
        } else if state == .Ready {
            
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
    
    func isBallInArea(node: SKSpriteNode, hard: Bool) -> Bool {
        let pos = ballNode.position
        
        let xL = node.position.x - node.size.width / 2 + (hard ? ballRadius : -ballRadius)
        let xR = node.position.x + node.size.width / 2 + (hard ? -ballRadius : ballRadius)
        let yU = node.position.y + node.size.height / 2 + (hard ? -ballRadius : ballRadius)
        let yD = node.position.y - node.size.height / 2 + (hard ? ballRadius : -ballRadius)
        
        return xL < pos.x && xR > pos.x && yU > pos.y && yD < pos.y
    }
    
    func restart(levelN: Int) -> Void {
        if levelNode.children.count > 0 { levelNode.removeAllChildren() }
        
        if levelN <= levelNum {
            if state == .GameOverPass || state == .GameOverFailed {
                scoreBoardAndMenuMoveOut()
            }
            
            let newLevel = level.refLevels[levelN]!.copy() as! SKReferenceNode
            levelNode.addChild(newLevel)
            initGame()
        } else {
            buttonHome.selectedHandler()
        }
    }
    
    func isStatic(v: CGVector) -> Bool {
        return abs(v.dx) < 0.0005 && abs(v.dy) < 0.0005
    }
    
    func gameOver() -> Void {
        if state == .Failed {
            state = .GameOverFailed
            if nowLevelNum > 3 {
                // save the states of all objects to reload next time
                saveObjsState()
            }
            resultLabel.text = " Failed..." //+ String(format: "%.3f", totalTime)
        } else if state == .Pass {
            if nowLevelNum > passedLevelNum {
                defaults.setInteger(nowLevelNum, forKey: "passedLevelNum")
            }
            bestTime = defaults.doubleForKey("best\(nowLevelNum)") ?? 0
            bestTimeScore()
            resultLabel.text = " Pass!" //+ String(format: "%.3f", totalTime)
            state = .GameOverPass
        } else {
            return
        }
        ballNode.hidden = true
        ballNode.position = CGPoint(x: -50, y: 50)
        levelNode.removeAllChildren()
        scoreBoardAndMenuMoveIn()
    }
    
    func gameOverNext() -> Void {
        scoreBoardAndMenuMoveOut()
        
        var reload = false
        if state == .GameOverPass {
            if nowLevelNum == levelNum {
                passedAllLevels() // todo, this is wrong way to identify if passed all levels
                return
            } else {
                nowLevelNum = nowLevelNum + 1
            }
        } else {
            reload = true
        }
        
        restart(nowLevelNum)
        state = .Ready
        if nowLevelNum > 3 && reload {
            reloadObjsState()
        }
    }
    
    func scoreBoardAndMenuMoveIn() -> Void {
        if let menuNode = menuNode.childNodeWithName("menuBgd") as? SKSpriteNode {
            self.menuNode.runAction(SKAction(named: "menuMoveUp")!)
            menuNode.physicsBody = SKPhysicsBody(rectangleOfSize: menuNode.size)
            menuNode.physicsBody?.dynamic = false
            menuNode.physicsBody?.affectedByGravity = false
            scoreBoard.physicsBody = SKPhysicsBody(rectangleOfSize: scoreBoard.size)
            scoreBoard.physicsBody?.dynamic = true
            scoreBoard.physicsBody?.affectedByGravity = true
            
            let tapTodo = scoreBoard.childNodeWithName("tapTodo") as! SKLabelNode
            if nowLevelNum < 5 {
                tapTodo.removeAllActions()
                tapTodo.runAction(SKAction(named: "fadeInAndOut")!)
            } else {
                tapTodo.removeAllActions()
                tapTodo.runAction(SKAction.fadeOutWithDuration(0.1))
            }
        }
    }
    
    func scoreBoardAndMenuMoveOut() -> Void {
        if scoreBoard.physicsBody != nil {
            let tapTodo = scoreBoard.childNodeWithName("tapTodo") as! SKLabelNode
            if nowLevelNum < 5 {
                tapTodo.removeAllActions()
                tapTodo.runAction(SKAction.fadeOutWithDuration(0.32))
            }
            scoreBoard.physicsBody = nil
            let ani = SKAction.moveTo(CGPoint(x: screenWidth / 2, y: 872), duration: 0.6)
            ani.timingMode = SKActionTimingMode.EaseOut
            scoreBoard.runAction(ani)
            menuNode.runAction(SKAction(named: "menuMoveDown")!)
            menuNode.childNodeWithName("menuBgd")!.physicsBody = nil
        }
    }
    
    func enableMultiTouch() -> Void {
        self.view?.multipleTouchEnabled = true
    }
    
    func disableMultiTouch() -> Void {
        self.view?.multipleTouchEnabled = false
    }
    
    func cropRoundCorner(node: SKSpriteNode) -> Void {
        let w: CGFloat = node.size.width
        let h: CGFloat = node.size.height
        let cropNode = SKCropNode()
        let mask = SKShapeNode()
        mask.path = CGPathCreateWithRoundedRect(CGRectMake(-w / 2, -h / 2, w, h), 9, 9, nil)
        mask.fillColor = node.color
        mask.strokeColor = node.color
        
        cropNode.maskNode = mask
        let parent = node.parent!
        parent.addChild(cropNode)
        cropNode.position = node.position
        node.removeFromParent()
        cropNode.addChild(node)
    }
    
    func initGame() -> Void {
        let initial = "this is initGame"
        
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
        state = .Ready
        pastTime = 0
        pastTimeStart = 0
        pastStaticTime = 0
        staticTime = 0
        touched = false
        multiTouching = false
        ballNode.hidden = false
        ballNode.physicsBody?.angularVelocity = 0
        ballNode.physicsBody?.dynamic = true
        ballNode.physicsBody?.affectedByGravity = false
        ballNode.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        ballNode.zRotation = 0
        objNodeIndex.removeAll()
        objNodeIndex["ball"] = 0
        nowNode = ballNode
        nowNodeIndex = 0
        stateBar.alpha = 0
        stateBar.zPosition = 12
        stateBar.hidden = true
        rotationNode.alpha = 0
        functionNode.alpha = 0
 
        timeLabel.text = "0.000"
        bestTime = defaults.doubleForKey("best\(nowLevelNum)") ?? 0
        objNodes = levelNode.childNodeWithName("//objNodes")
        startNode = levelNode.childNodeWithName("//start") as! SKSpriteNode
        endNode = levelNode.childNodeWithName("//end") as! SKSpriteNode
        obstacleLayer = levelNode.childNodeWithName("//obstacleLayer")
        obstacleLayer?.removeFromParent()
        tutorialLayer = levelNode.childNodeWithName("//tutorialLayer")
        tutorialLayerBg = tutorialLayer?.childNodeWithName("tutorialBg") as? SKSpriteNode
        countObjNodeIndex()

        nowNode.position = startNode.position // init position
        lastTouchLocation = ballNode.position
        lastTouchNodeLocation = ballNode.position
                
        passedLevelNum = defaults.integerForKey("passedLevelNum")
        totalTime = defaults.doubleForKey("totalTime")
        
        levelTutorial = levelTutorialStates
        initTutorial() // make a tutorial if necessary
    }
    
    func countObjNodeIndex() -> Void {
        for (n, obj) in objNodes.children.enumerate() {
            objNodeIndex[obj.name!] = n + 1
            let zr = obj.zRotation
            let pos = obj.position
            let zero = CGPoint(x: 0, y: 0)
            if obj.position != zero {
                obj.position = zero
                obj.children.first!.children.first!.position = pos
                obj.zRotation = 0
                obj.children.first!.children.first!.zRotation = zr
            }
        }
    }
    
    func initTutorial() -> Void {
        if let tutorial = self.tutorialLayer {
            popLastTutorialState()
            
            for node in tutorial.children { node.alpha = 0 }
            
            tutorialLayerBg!.removeAllActions()
            tutorialLayerBg!.zPosition = 0
            if tutorialState != .Done {
                tutorialLayerBg!.runAction(SKAction.afterDelay(0.4, performAction: SKAction.fadeInWithDuration(0.48)))
            }
            
            if let skip = childNodeWithName("//skipLabelArea") as? MSButtonNode {
                skip.selectedHandler = {
                    skip.parent!.runAction(SKAction.fadeOutWithDuration(0.24))
                    self.tutorialLayer?.hidden = true
                    self.tutorialLayer?.removeFromParent()
                    self.levelTutorial[self.nowLevelNum] = []
                    self.tutorialState = .Done
                }
            }
        }
    }
    
    func buttonGoSelector() -> Void {
        self.objState.objPos[self.ballNode.name!] = self.ballNode.position
        self.ballNode.physicsBody?.affectedByGravity = true
        self.state = .Dropping
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
        self.nowNode.runAction(SKAction(named: "scaleToFocus")!)
    }

    func passedAllLevels() -> Void {
        defaults.setBool(true, forKey: "passedAll")
        if let scene = Home(fileNamed: "Home") {
            let skView = self.view as SKView!
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            scene.scaleMode = scaleMode
            scene.fromGameScenePassedAll = true
            skView.presentScene(scene)
        }
    }
    
    func bestTimeScore() -> Void {
        if pastTime > 0 && Double(pastTime) < bestTime || bestTime == 0 {
            totalTime -= bestTime
            bestTime = Double(pastTime)
            totalTime += bestTime
            totalTime = totalTime < 0 ? 0 : totalTime
            defaults.setDouble(totalTime, forKey: "totalTime")
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
    
    func checkStateBar() -> Void {
        if stateBar.alpha != 0 {
            stateBar.runAction(SKAction(named: "fadeOutHide")!)
        }
        stateBar.removeAllChildren()
    }
    
    func updateObjMove(location: CGPoint) -> Void {
        var pos = location + lastTouchNodeLocation - lastTouchLocation
        if nowNode == ballNode {
            // ball hit wall cases
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
                        var a = bounceFunctionV1!.dy / abs(bounceFunctionV1!.dy)
                        let b1 = stateBar.childNodeWithName("smallBall1")!.physicsBody
                        let b2 = stateBar.childNodeWithName("smallBall2")!.physicsBody
                        let bar = stateBar.childNodeWithName("bounceBar") as! SKSpriteNode
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
                        let b = stateBar.childNodeWithName("smallBall")!.physicsBody
                        if shortStick.direction != "left" && dx < 0 {
                            shortStick.direction = "left"
                            b?.velocity = CGVector(dx: 0, dy: 0)
                            b?.applyImpulse(CGVector(dx: -5, dy: 0))
                            nowNode.runAction(SKAction.rotateToAngle(angleToRadian(60), duration: 0.21))
                        } else if shortStick.direction != "right" && dx > 0 {
                            shortStick.direction = "right"
                            b?.velocity = CGVector(dx: 0, dy: 0)
                            b?.applyImpulse(CGVector(dx: 5, dy: 0))
                            nowNode.runAction(SKAction.rotateToAngle(0, duration: 0.21))
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
                        let bar = stateBar.childNodeWithName("stickBar") as! SKSpriteNode
                        bar.xScale = stick.xScale
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
                        let bounceBar = SKSpriteNode(color: UIColor.whiteColor(), size: CGSize(width: screenWidth * bounce.k / bounce.kMax, height: menuHeight))
                        bounceBar.name = "bounceBar"
                        bounceBar.alpha = 0.4
                        let smallBall = SKSpriteNode(imageNamed: "ballIcon")
                        let groundTop = SKShapeNode(rectOfSize: CGSize(width: screenWidth, height: 2))
                        let groundBottom = SKShapeNode(rectOfSize: CGSize(width: screenWidth, height: 2))
                        groundTop.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: screenWidth, height: 2))
                        groundBottom.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: screenWidth, height: 2))
                        smallBall.physicsBody = SKPhysicsBody(circleOfRadius: smallBall.size.width / 2)
                        groundTop.physicsBody?.dynamic = false
                        groundBottom.physicsBody?.dynamic = false
                        groundBottom.physicsBody?.contactTestBitMask = 1
                        groundTop.physicsBody?.contactTestBitMask = 1
                        groundTop.physicsBody?.categoryBitMask = 5
                        groundBottom.physicsBody?.categoryBitMask = 5
                        smallBall.physicsBody?.dynamic = true
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
                        let ground = SKShapeNode(rectOfSize: CGSize(width: screenWidth, height: 3))
                        smallBall.name = "smallBall"
                        smallBall.physicsBody = SKPhysicsBody(circleOfRadius: smallBall.size.width / 2)
                        smallBall.physicsBody?.dynamic = true
                        smallBall.physicsBody?.affectedByGravity = true
                        smallBall.physicsBody?.allowsRotation = true
                        ground.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: screenWidth, height: 3))
                        ground.physicsBody?.dynamic = false
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
                        let stickBar = SKSpriteNode(color: UIColor.whiteColor(), size: CGSize(width: screenWidth / 2, height: menuHeight))
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
        for (i, obj) in objs.enumerate() {
            for j in (i + 1) ..< objs.count {
                let objA = obj.children.first!.children.first!
                let objB = objs[j].children.first!.children.first!
                for a in objA.children {
                    for b in objB.children {
                        if a.intersectsNode(b) {
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
            let node = obj.children.first!.children.first!
            let objNode = objState.objClass[name]!
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
    
    // no use
    func loadLevelN(n: Int) -> Void {
        if levelNode.children.count == 0 {
            let levelPath = NSBundle.mainBundle().pathForResource("Level\(n)", ofType: "sks")
            let newLevel = SKReferenceNode(URL: NSURL(fileURLWithPath: levelPath!))
            newLevel.name = "level\(n)"
            nowLevelNum = n
            levelNode.addChild(newLevel)
        }
    }

    func tutorialTouchMoving(pos: CGPoint) -> Void {
        if let path = NSBundle.mainBundle().pathForResource("TouchIcon", ofType: "sks") {
            
            let label = SKLabelNode(text: "Hold to move current object")
            levelNode.addChild(label)
            label.name = "tutorialMovingLabel"
            label.position = CGPoint(x: 187.5, y: 484)
            label.zPosition = 50
            label.fontSize = 23
            let bg = SKShapeNode.init(rect: CGRect(origin: CGPoint(x: -151, y: -14), size: CGSize(width: 302, height: 48)), cornerRadius: 8.4)
            bg.fillColor = UIColor.blackColor()
            bg.strokeColor = UIColor.blackColor()
            bg.alpha = 0.32
            label.addChild(bg)
            
            let touchIcon = SKReferenceNode(URL: NSURL(fileURLWithPath: path))
            touchIcon.position = pos
            touchIcon.zPosition = 28
            touchIcon.name = "tutorialHelp"
            tutorialLayer!.addChild(touchIcon)
            
            let handIcon = SKSpriteNode(imageNamed: "oneFinger")
            touchIcon.addChild(handIcon)
            handIcon.position = CGPoint(x: 8, y: -56)

            let touchIn = touchIcon.childNodeWithName("//touchIn") as! SKSpriteNode
            let touchFadeTo4 = SKAction.fadeAlphaTo(0.4, duration: 0.7)
            let touchFadeTo8 = SKAction.fadeAlphaTo(0.8, duration:0.7)
            let touchFadeTo2 = SKAction.fadeAlphaTo(0.2, duration: 0.7)
            let touchFadeTo6 = SKAction.fadeAlphaTo(0.6, duration: 0.7)
            let touchFadeOut = SKAction.fadeOutWithDuration(0.5)
            let touchFadeIn = SKAction.fadeInWithDuration(0.3)
            
            let touchDelay = SKAction.waitForDuration(1.7)
            let touchFade = SKAction.sequence([touchFadeTo4, touchFadeTo8, touchFadeTo2, touchFadeTo6])
            let touchAction = SKAction.sequence([touchFade, touchFadeOut, touchFade, touchFadeIn, touchDelay])
            touchIn.runAction(SKAction.repeatActionForever(touchAction))

//            let movingDistance = 80
//
//            let touchMove = SKAction.moveBy(CGVector(dx: -movingDistance, dy: 0), duration: 1)
//            let touchMoveBack = SKAction.moveBy(CGVector(dx: movingDistance, dy: 0), duration: 0.6)
//            let touchMF = SKAction.sequence([touchMove, touchFadeOut, touchMoveBack, touchFadeIn])
//            touchMF.timingMode = SKActionTimingMode.EaseInEaseOut
//
//            touchAction.timingMode = SKActionTimingMode.EaseInEaseOut
//
//            let repeatMF = SKAction.repeatActionForever(touchMF)
//
//            touchIcon.runAction(repeatMF)
//            if nowNode != ballNode {
//                nowNode.runAction(repeatMF)
//            }
        }
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
        let label4 = SKLabelNode(text: "Now you can move it like this...")
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
        label.runAction(SKAction.afterDelay(0.1, performAction: SKAction.fadeInWithDuration(0.4)))
        
        let bg = SKShapeNode.init(rect: CGRect(origin: CGPoint(x: -142, y: -92.8), size: CGSize(width: 284, height: 128)), cornerRadius: 8.4)
        bg.fillColor = UIColor.blackColor()
        bg.strokeColor = UIColor.blackColor()
        bg.alpha = 0.32
        label.addChild(bg)
    }
    
    func introStartLabelActions() -> Void {
        let arrowStart = tutorialLayer!.childNodeWithName("arrowStart")
        let labelStart = tutorialLayer!.childNodeWithName("labelStart")
        
        let fadeInDelay = SKAction.afterDelay(0.32, performAction: SKAction.fadeInWithDuration(0.23))
        arrowStart?.runAction(fadeInDelay)
        labelStart?.runAction(fadeInDelay)
    }
    
    func introGoalLabelActions() -> Void {
        let arrowStart = tutorialLayer!.childNodeWithName("arrowStart")
        let labelStart = tutorialLayer!.childNodeWithName("labelStart")
        let arrowGoal = tutorialLayer!.childNodeWithName("arrowGoal")
        let labelGoal = tutorialLayer!.childNodeWithName("labelGoal")
        
        let hide = SKAction.hide()
        let fadeOut = SKAction.fadeOutWithDuration(0.8)
        let actOut = SKAction.sequence([fadeOut, hide])
        let fadeIn = SKAction.fadeInWithDuration(0.8)
        arrowStart?.runAction(actOut)
        labelStart?.runAction(actOut)
        arrowGoal?.runAction(SKAction.afterDelay(0.1, performAction: fadeIn))
        labelGoal?.runAction(SKAction.afterDelay(0.1, performAction: fadeIn))
    }
    
    func tutorialGo() -> Void {
        if nowLevelNum == 1 {
            childNodeWithName("//tutorialMovingLabel")?.removeFromParent()
            childNodeWithName("//tutorialMovingLabel2")?.removeFromParent()
        }
        tutorialLayerBg?.runAction(SKAction.fadeInWithDuration(0.23))
        
        let btnGo = buttonGo.copy() as! MSButtonNode
        levelNode.addChild(btnGo)
        btnGo.name = "tutorialHelp"
        btnGo.alpha = 0
        btnGo.position = buttonGo.position + menuNode.position
        btnGo.xScale = buttonGo.xScale
        btnGo.yScale = buttonGo.yScale
        btnGo.zPosition = 50
        btnGo.runAction(SKAction(named: "scaleToTouch1")!)
        btnGo.selectedHandler = {
            self.tutorialLayerBg!.runAction(SKAction.fadeOutWithDuration(0.32))
            self.buttonGoSelector()
            self.popLastTutorialState()
        }
    }
    
    func tutorialIcon() -> Void {
        if nowLevelNum == 1 {
            let arrowGoal = tutorialLayer!.childNodeWithName("arrowGoal")
            let labelGoal = tutorialLayer!.childNodeWithName("labelGoal")
            let hide = SKAction.hide()
            let fadeOut = SKAction.fadeOutWithDuration(0.8)
            let actOut = SKAction.sequence([fadeOut, hide])
            arrowGoal?.runAction(actOut)
            labelGoal?.runAction(actOut)
        }
        
        if tutorialLayerBg?.alpha == 0 {
            tutorialLayerBg?.runAction(SKAction.fadeInWithDuration(0.27))
        }
        
        let label = SKLabelNode(text: "Tap to change current object")
        menuNode.addChild(label)
        label.name = "tutorialHelp"
        label.position = CGPoint(x: 0, y: 57) + objIconNode.position
        label.zPosition = 50
        label.fontSize = 17
        
        let arrow = SKSpriteNode(texture: SKTexture(imageNamed: "arrowIcon"))
        label.addChild(arrow)
        arrow.position -= CGPoint(x: 0, y: 22)
        arrow.zRotation = angleToRadian(180)
        arrow.zPosition = 50
        
        let objIcon = objIconNode.copy() as! MSButtonNode
        label.addChild(objIcon)
        objIcon.alpha = 0
        objIcon.zPosition = 50
        objIcon.position = CGPoint(x: 0, y: -57)
        objIcon.runAction(SKAction(named: "scaleToTouch")!)
        objIcon.selectedHandler = {
            self.tutorialLayerBg!.runAction(SKAction.fadeOutWithDuration(0.32))
            self.buttonObjIconSelector()
            self.popLastTutorialState()
        }
        
        label.alpha = 0
        label.runAction(SKAction.afterDelay(0.23, performAction: SKAction.fadeInWithDuration(0.4)))
    }
    
    func popLastTutorialState() -> Void {
        if let ts = levelTutorial[nowLevelNum]?.popLast() {
            tutorialState = ts
        } else {
            tutorialState = .Done
        }
    }

    // no use
    func nowNodeFadeIn(x: CGFloat) -> Void {
        if nowNode != ballNode {
            nowNode.removeAllActions()
            nowNode.position.x = x
            nowNode.runAction(SKAction.fadeInWithDuration(0.32))
        }
    }
    
    func tutorialBeforeIconLongPress() -> Void {
        let label = SKLabelNode(text: "Wait, where is my bounce???")
        levelNode.addChild(label)
        label.name = "tutorialHelp"
        label.position = CGPoint(x: screenWidth / 2, y: 248)
        label.zPosition = 50
        label.fontSize = 21
        let bg = SKShapeNode.init(rect: CGRect(origin: CGPoint(x: -156, y: -18), size: CGSize(width: 312, height: 52)), cornerRadius: 8.4)
        bg.fillColor = UIColor.blackColor()
        bg.strokeColor = UIColor.blackColor()
        bg.alpha = 0.32
        label.addChild(bg)
        label.alpha = 0
        label.runAction(SKAction.afterDelay(0.2, performAction: SKAction.fadeInWithDuration(0.2)))
    }
    
    func tutorialIconLongPress() -> Void {
        tutorialLayerBg!.runAction(SKAction.fadeInWithDuration(0.28))
        
        let label = SKLabelNode(text: "Long press the icon")
        menuNode.addChild(label)
        label.name = "tutorialHelp"
        label.position = CGPoint(x: 0, y: 57) + objIconNode.position
        label.zPosition = 50
        label.fontSize = 17
        
        let arrow = SKSpriteNode(texture: SKTexture(imageNamed: "arrowIcon"))
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
        objIcon.runAction(SKAction(named: "scaleToTouch")!)
        
    }
    
    func tutorialIconLongPressNext() -> Void {
        let label = SKLabelNode(text: "Cool, here it is~")
        levelNode.addChild(label)
        label.name = "tutorialHelp"
        label.position = CGPoint(x: screenWidth / 2, y: 248)
        label.zPosition = 50
        label.fontSize = 21
        let bg = SKShapeNode.init(rect: CGRect(origin: CGPoint(x: -156, y: -18), size: CGSize(width: 312, height: 52)), cornerRadius: 8.4)
        bg.fillColor = UIColor.blackColor()
        bg.strokeColor = UIColor.blackColor()
        bg.alpha = 0.32
        label.addChild(bg)
        label.alpha = 0
        label.runAction(SKAction.afterDelay(0.84, performAction: SKAction.fadeInWithDuration(0.2)))
    }
    
    func tutorialFunctionIcon() -> Void {
        var mainText = "This is button Y"
        var funcText = "Try to drag it to leftside"
        var w = 208
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
        bg.fillColor = UIColor.blackColor()
        bg.strokeColor = UIColor.blackColor()
        bg.alpha = alpha
        label.addChild(bg)
        let label2 = SKLabelNode(text: funcText)
        label2.position = CGPoint(x: 0, y: -31)
        label2.zPosition = 50
        label2.fontSize = 20
        label.addChild(label2)
        
        let arrow = SKSpriteNode(texture: SKTexture(imageNamed: "arrowIcon"))
        label.addChild(arrow)
        arrow.position -= CGPoint(x: 0, y: -60)
        arrow.zPosition = 50
        
        label.alpha = 0
        label.runAction(SKAction.afterDelay(0.23, performAction: SKAction.fadeInWithDuration(0.4)))
    }
    
    func tutorialStateBar() -> Void {
        childNodeWithName("//tutorialHelp")?.runAction(SKAction.fadeOutWithDuration(0.23))
        
        let label = SKLabelNode(text: "State bar will be shown here")
        levelNode.addChild(label)
        label.name = "tutorialState"
        label.position = CGPoint(x: screenWidth / 2, y: 125)
        label.zPosition = 50
        label.fontSize = 21
        let bg = SKShapeNode.init(rect: CGRect(origin: CGPoint(x: -142, y: -17), size: CGSize(width: 284, height: 51)), cornerRadius: 8.4)
        bg.fillColor = UIColor.blackColor()
        bg.strokeColor = UIColor.blackColor()
        bg.alpha = 0.32
        label.addChild(bg)
        
        let arrow = SKSpriteNode(texture: SKTexture(imageNamed: "arrowIcon"))
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
        bg.fillColor = UIColor.blackColor()
        bg.strokeColor = UIColor.blackColor()
        bg.alpha = 0.36
        label.addChild(bg)
        
        label.alpha = 0
        label.runAction(SKAction.afterDelay(0.777, performAction: SKAction.fadeInWithDuration(0.4)))
    }
    
    func tutorialTapBounce() -> Void {
        if let bounce = childNodeWithName("//bounceRF") {
            let pos = bounce.children.first!.children.first!.position
            
            let label = SKLabelNode(text: "Tap the bounce")
            levelNode.addChild(label)
            label.name = "tutorialHelp"
            label.position = pos + CGPoint(x: 0, y: -72)
            label.zPosition = 50
            label.fontSize = 21

            let arrow = SKSpriteNode(texture: SKTexture(imageNamed: "arrowIcon"))
            label.addChild(arrow)
            arrow.position -= CGPoint(x: 0, y: -41)
            arrow.zPosition = 50
            
            label.alpha = 0
            label.runAction(SKAction.afterDelay(0.24, performAction: SKAction.fadeInWithDuration(0.4)))
            
            let b = bounce.copy() as! SKNode
            label.addChild(b)
            b.position = CGPoint(x: 0, y: 72)
            let scaleLarge = SKAction.scaleTo(1.24, duration: 0.48)
            let scale = SKAction.scaleTo(1, duration: 0.36)
            let delay = SKAction.waitForDuration(1.24)
            let action = SKAction.sequence([scale, delay, scaleLarge])
            scaleLarge.timingMode = SKActionTimingMode.EaseInEaseOut
            scale.timingMode = SKActionTimingMode.EaseInEaseOut
            b.runAction(SKAction.repeatActionForever(action))
            
        }
    }

}
