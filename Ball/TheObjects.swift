//
//  TheObjects.swift
//  Ball
//
//  Created by 高宇超 on 7/13/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit

class TheObjects: SKSpriteNode {
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let gameScene = self.scene as? GameScene {
            if gameScene.state == .Ready && gameScene.tutorialState == .Done {
                if touches.count == 1 {
                    if self.parent?.name != nil {
                        gameScene.rotationNode.runAction(SKAction(named: "fadeOut")!)
                        gameScene.functionNode.runAction(SKAction(named: "fadeOut")!)
                        if gameScene.nowNode != self.parent! {
                            gameScene.nowNode = self.parent!
                            gameScene.objIconNode.runAction(SKAction(named: "scaleToFocus")!)
                        }
                    }
                }
            } else if gameScene.tutorialState == .TapBounce {
                if touches.count == 1 {
                    let touch = touches.first!
                    let node = nodeAtPoint(touch.locationInNode(self)).parent
                    if let name = node?.name {
                        if name == "bounce" {
                            node?.removeFromParent()
                            gameScene.popLastTutorialState()
                            gameScene.tutorialLayerBg?.runAction(SKAction.fadeOutWithDuration(0.23))
                            gameScene.nowNode = gameScene.childNodeWithName("//bounce")!
                            gameScene.objIconNode.runAction(SKAction(named: "scaleToFocus")!)
                        }
                    }
                }
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let gameScene = self.scene as? GameScene {
            if gameScene.nowNode == self.parent! {
                if gameScene.state == .Ready && gameScene.tutorialState == .Done {
                    if touches.count == 1 {
                        gameScene.disableMultiTouch()
                        gameScene.rotationNode.runAction(SKAction(named: "fadeOut")!)
                        gameScene.functionNode.runAction(SKAction(named: "fadeOut")!)
                        for touch in touches {
                            // self.parent!.parent!.parent is the SKReferenceNode in GameScene
                            self.parent!.position = touch.locationInNode(self.parent!.parent!)
                        }
                    }
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let gameScene = self.scene as? GameScene {
            if gameScene.nowNode == self.parent! {
                if gameScene.state == .Ready && gameScene.tutorialState == .Done {
                    if touches.count == 1 {
                        for touch in touches {
                            gameScene.lastTouchNodeLocation = self.parent!.position
                            gameScene.lastTouchLocation = touch.locationInNode(gameScene)
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
        userInteractionEnabled = true
    }

}