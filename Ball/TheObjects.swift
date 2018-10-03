//
//  TheObjects.swift
//  Ball
//
//  Created by 高宇超 on 7/13/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit

class TheObjects: SKSpriteNode {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let gameScene = self.scene as? GameScene {
            if gameScene.state == .ready && gameScene.tutorialState == .done {
                if touches.count == 1 {
                    if self.parent?.name != nil {
                        gameScene.rotationNode.run(SKAction(named: "fadeOut")!)
                        gameScene.functionNode.run(SKAction(named: "fadeOut")!)
                        if gameScene.nowNode != self.parent! {
                            gameScene.nowNode = self.parent!
                            gameScene.objIconNode.run(SKAction(named: "scaleToFocus")!)
                        }
                    }
                }
            } else if gameScene.tutorialState == .tapBounce {
                if touches.count == 1 {
                    let touch = touches.first!
                    let node = atPoint(touch.location(in: self)).parent
                    if let name = node?.name {
                        if name == "bounce" {
                            node?.removeFromParent()
                            gameScene.popLastTutorialState()
                            gameScene.tutorialLayerBg?.run(SKAction.fadeOut(withDuration: 0.23))
                            gameScene.nowNode = gameScene.childNode(withName: "//bounce")!
                            gameScene.objIconNode.run(SKAction(named: "scaleToFocus")!)
                        }
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let gameScene = self.scene as? GameScene {
            if gameScene.nowNode == self.parent! {
                if gameScene.state == .ready && gameScene.tutorialState == .done {
                    if touches.count == 1 {
                        gameScene.disableMultiTouch()
                        gameScene.rotationNode.run(SKAction(named: "fadeOut")!)
                        gameScene.functionNode.run(SKAction(named: "fadeOut")!)
                        for touch in touches {
                            // self.parent!.parent!.parent is the SKReferenceNode in GameScene
                            self.parent!.position = touch.location(in: self.parent!.parent!)
                        }
                    }
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let gameScene = self.scene as? GameScene {
            if gameScene.nowNode == self.parent! {
                if gameScene.state == .ready && gameScene.tutorialState == .done {
                    if touches.count == 1 {
                        for touch in touches {
                            gameScene.lastTouchNodeLocation = self.parent!.position
                            gameScene.lastTouchLocation = touch.location(in: gameScene)
                            gameScene.updateRF()
                        }
                    }
                }
            }
            gameScene.enableMultiTouch()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isUserInteractionEnabled = true
    }

}
