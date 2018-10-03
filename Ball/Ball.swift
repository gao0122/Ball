//
//  Ball.swift
//  Ball
//
//  Created by 高宇超 on 7/8/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit

class Ball: SKSpriteNode {
    
    let objName = "The ball"
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let gameScene = self.scene as? GameScene {
            if gameScene.state == .ready && gameScene.tutorialState == .done {
                if touches.count == 1 {
                    gameScene.rotationNode.run(SKAction(named: "fadeOut")!)
                    gameScene.functionNode.run(SKAction(named: "fadeOut")!)
                    if gameScene.nowNode != self {
                        gameScene.nowNode = self
                        gameScene.objIconNode.run(SKAction(named: "scaleToFocus")!)
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let gameScene = self.scene as? GameScene {
            if gameScene.nowNode == self {
                if gameScene.state == .ready && gameScene.tutorialState == .done {
                    if touches.count == 1 {
                        gameScene.disableMultiTouch()
                        gameScene.rotationNode.run(SKAction(named: "fadeOut")!)
                        gameScene.functionNode.run(SKAction(named: "fadeOut")!)
                        for touch in touches {
                            self.position = touch.location(in: gameScene)
                        }
                    }
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let gameScene = self.scene as? GameScene {
            if gameScene.nowNode == self {
                if gameScene.state == .ready && gameScene.tutorialState == .done {
                    if touches.count == 1 {
                        for touch in touches {
                            gameScene.lastTouchNodeLocation = position
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
