
//
//  Level.swift
//  Don't Drop Me!
//
//  Created by 高宇超 on 7/6/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit
import GameKit
import StoreKit

class Level: SKScene, GKGameCenterControllerDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    var list = [SKProduct]()
    var p = SKProduct()
    let unlockId = "YPuzzleUnlockAllLevels"
    let unlock = false
    
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
    var buttonUnlock: MSButtonNode!
    
    var defaults: UserDefaults!
    
    var refHome: SKReferenceNode!
    var refLevels = [Int: SKReferenceNode!]()
    
    var scrollBegan = false
    var lastLevelPos: CGPoint!
    var lastTouchPos: CGPoint!
    
    var fromGameScenePassedAll = false
    var firstTimestamp: TimeInterval = -1
    
    var gcd = false // game center authenticated
    
    override func didMove(to view: SKView) {
        
        defaults = UserDefaults.standard
        chosen = false
        scrollBegan = false
        
        if fromGameScenePassedAll {
            // pass all
        }
        
        /* Set the scale mode to scale to fit the window */
        gameScene.scaleMode = scaleMode
        //gameScene.anchorPoint.x = 0.5
        if gameScene.level == nil { gameScene.level = self }
        gameLevelNode = gameScene.childNode(withName: "levelNode")!
        homeNode = childNode(withName: "homeNode")!
        if refHome == nil {
            refHome = SKReferenceNode(url: URL(fileURLWithPath: Bundle.main.path(forResource: "Home", ofType: "sks")!))
            homeNode.addChild(self.refHome)
        }
        
        menuNode = childNode(withName: "menu")!
        bestTimeLabel = menuNode.childNode(withName: "bestTimeLabel") as! SKLabelNode
        buttonHome = menuNode.childNode(withName: "buttonHome") as! MSButtonNode
        buttonGC = menuNode.childNode(withName: "gameCenter") as! MSButtonNode
        levels = childNode(withName: "levels")!
        levels.position = CGPoint(x: screenWidth / 2, y: 366)
        levels.isHidden = false
        levels.alpha = 0
        levels.run(SKAction.afterDelay(0.19, performAction: SKAction.fadeIn(withDuration: 0.42)))
        childNode(withName: "scrollUp")?.zPosition = 5
        buttonUnlock = childNode(withName: "unlockAllArea") as! MSButtonNode
        
        bestTimeLabel.alpha = 0
        totalTime = 520
        firstTimestamp = -1
        fromGameScenePassedAll = false
        
        //defaults.setBool(unlock, forKey: "unlockedAll")
        if SKPaymentQueue.canMakePayments() {
            print("IAP is enabled...")
            let productId: Set = [unlockId]
            let request: SKProductsRequest = SKProductsRequest(productIdentifiers: productId)
            request.delegate = self
            request.start()
        } else {
            print("please enable IAPS")
        }
        
        checkLevels()
        buttonHome.selectedHandler = {
            self.levels.run(SKAction.fadeOut(withDuration: 0.17))
            let cameraMove = SKAction.move(to: CGPoint(x: self.camera!.position.x, y: screenHeight * 1.5), duration: 1)
            self.camera?.run(cameraMove)
        }
        buttonGC.selectedHandler = gameCenter
        buttonUnlock.selectedHandler = buyUnlock
        
        checkTimeScore()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if GKLocalPlayer.localPlayer().isAuthenticated {
            defaults.set(false, forKey: "notGcPlayer")
            defaults.synchronize()
        }
        if levels.alpha < 1 { levels.run(SKAction.fadeIn(withDuration: 0.21)) }
        if chosen { return }
        if touches.count == 1 {
            let touch = touches.first!
            let pos = touch.location(in: self)
            lastLevelPos = levels.position
            lastTouchPos = pos
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 {
            scrollBegan = true
            let touch = touches.first!
            let pos = touch.location(in: self)
            levels.position.y = pos.y - lastTouchPos.y + lastLevelPos.y
            _ = levels.position.y.clamp(366, 800)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollBegan {
            if touches.count == 1 {
                scrollBegan = false
            }
        } else if touches.count == 1 {
            let touch = touches.first!
            let pos = touch.location(in: self)
            let node = atPoint(pos)
            if node.name == "unlockAll" {
                buyProduct()
                return
            } else if node.name == "restorePurchaseLabel" {
                restorePurchase()
                return
            }
            for n in 1...levelNum {
                if node.name == "level\(n)" || node.name == "level\(n)Area" {
                    if n <= 15 || defaults.double(forKey: "best\(n)") < 10 || defaults.double(forKey: "best\(n - 1)") < 10  || defaults.bool(forKey: "unlockedAll") {
                        
                        moveToLevelN(n, name: node.name!)
                        return
                    }
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
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
            skView?.showsPhysics = showPhy
            skView?.ignoresSiblingOrder = true
            home.scaleMode = scaleMode
            home.anchorPoint.x = 0.5
            home.ballNode.removeAllActions()
            home.ballNode.isHidden = false
            home.ballNode.alpha = 1
            home.ballNode.position = home.startPos
            home.ballNode.physicsBody?.isDynamic = false
            self.home.playLabel.removeAllActions()
            self.home.playLabel.run(SKAction.fadeIn(withDuration: 0.2))
            skView?.presentScene(home)
            camera?.position.y = screenHeight / 2
        }
        
    }
    
    func moveToLevelN(_ n: Int, name: String!) -> Void {
        checkTimeScore()
        if refLevels[n] == nil { return }
        gameLevelNode.removeAllChildren()
        gameLevelNode.addChild(refLevels[n]!.copy() as! SKReferenceNode)
        gameScene.objState = ObjState(levelNum: n)
        gameScene.nowLevelNum = n
        
        let skView = self.view as SKView!
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView?.ignoresSiblingOrder = true
        skView?.showsPhysics = showPhy
        skView?.showsNodeCount = showNodes
        
        skView?.presentScene(gameScene, transition: SKTransition.crossFade(withDuration: 0.7))
        chosen = true
    }
    
    func loadLevelN(_ n: Int) -> Void {
        if refLevels[n] == nil {
            if let path = Bundle.main.path(forResource: "Level\(n)", ofType: "sks") {
                refLevels[n] = SKReferenceNode(url: URL(fileURLWithPath: path))
                refLevels[n]!.name = "level\(n)"
            }
        }
    }
    
    func checkTimeScore() -> Void {
        var total: Double = 520
        for n in 1...levelNum {
            let time = defaults.double(forKey: "best\(n)")
            if time < 10 {
                total -= 10
                total += time
            }
        }
        totalTime = total
        defaults.set(total, forKey: "totalTime")
        defaults.synchronize()
        
        //let change: dispatch_block_t = {}
        if self.totalTime == 1 {
            self.bestTimeLabel.text = String(format: "%.3f", self.totalTime) + " second"
        } else {
            self.bestTimeLabel.text = String(format: "%.3f", self.totalTime) + " seconds"
        }
        bestTimeLabel.run(SKAction.fadeIn(withDuration: 0.23))
    }
    
    func gameCenter() -> Void {
        if GKLocalPlayer.localPlayer().isAuthenticated {
            showLeaderBoard()
        } else {
            authPlayer()
        }
    }
    
    func showLeaderBoard() -> Void {
        let viewController = self.view!.window?.rootViewController
        let gcvc = GKGameCenterViewController()
        gcvc.viewState = GKGameCenterViewControllerState.leaderboards
        
        gcvc.gameCenterDelegate = self
        viewController?.present(gcvc, animated: true, completion: nil)
    }
    
    func authPlayer() -> Void {
        if !gcd {
            gcd = true
            
            let localPlayer = GKLocalPlayer.localPlayer()
            localPlayer.authenticateHandler = {
                (view, error) in
                if view != nil {
                    self.view!.window?.rootViewController?.present(view!, animated: true, completion: nil)
                }
            }
        } else {
            showLeaderBoard()
        }
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    func checkLevels() -> Void {
        let green = UIColor(red: 28 / 256, green: 242 / 256, blue: 118 / 256, alpha: 1)
        self.bestTimeLabel.run(SKAction.fadeOut(withDuration: 0.12))
        for n in 1...levelNum {
            let node = levels.childNode(withName: "level\(n)") as! SKLabelNode
            var score = defaults.double(forKey: "best\(n)")
            if score == 0 {
                defaults.set(10, forKey: "best\(n)")
                defaults.synchronize()
                score = 10
            }
            
            loadLevelN(n)
            
            if defaults.bool(forKey: "passedAll") {
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
                    if score == 10 && defaults.double(forKey: "best\(n - 1)") < 10 {
                        node.fontName = fontPass
                        node.fontColor = UIColor.white
                    } else {
                        node.fontName = fontDefault
                        node.fontColor = UIColor.white
                    }
                }
                if defaults.bool(forKey: "unlockedAll") || n <= 15 {
                    // unlocked - UI
                    node.fontName = fontPass
                }
            }
        }
    }
    
    func restorePurchase() -> Void {
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
        
        let vc = view?.window?.rootViewController
        let alert = UIAlertController(title: "Restore purchase", message: "Your purchase has been restored!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        vc?.present(alert, animated: true, completion: nil)
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        defaults.set(false, forKey: "unlockedAll")
        for transaction in queue.transactions {
            if let error = transaction.error {
                print(error)
            }
            let id = transaction.payment.productIdentifier
            print(id)
            if id == unlockId {
                print("transaction restored")
                defaults.set(true, forKey: "unlockedAll")
                checkLevels()
            }
        }
    }
    
    func buyUnlock() -> Void {
        for product in list {
            let pId = product.productIdentifier
            if pId == unlockId {
                p = product
                buyProduct()
                break
            }
        }
    }
    
    func buyProduct() -> Void {
        print("buy " + p.productIdentifier)
        
        let payment = SKPayment(product: p)
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(payment as SKPayment)
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("product request")
        
        for product in response.products {
            print("product added")
            print(product.productIdentifier)
            print(product.localizedTitle)
            print(product.localizedDescription)
            print(product.price)
            print()
            list.append(product)
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("add payment")
        
        for transaction in transactions {
            if let error = transaction.error {
                print(error)
            }
            switch transaction.transactionState {
            case .purchased:
                print("buy, unlocked")
                print(p.productIdentifier)
                defaults.set(true, forKey: "unlockedAll")
                checkLevels()
                queue.finishTransaction(transaction)
            case .failed:
                print("failed error")
                queue.finishTransaction(transaction)
            default:
                print("default \(transaction.transactionState)")
                break
            }
            
        }
    }
    
}
