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
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let gameScene = self.parent as! GameScene
        switch gameScene.state {
        case .Ready:
            if touches.count == 1 {
                gameScene.rotationNode.runAction(SKAction(named: "fadeOut")!)
                gameScene.functionNode.runAction(SKAction(named: "fadeOut")!)
                if gameScene.nowNode != self {
                    gameScene.nowNode = self
                }
            }
        case .Dropping:
            break
        default:
            break
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let gameScene = self.parent as! GameScene
        if gameScene.nowNode == self {
            switch gameScene.state {
            case .Ready:
                if touches.count == 1 {
                    gameScene.disableMultiTouch()
                    gameScene.rotationNode.runAction(SKAction(named: "fadeOut")!)
                    gameScene.functionNode.runAction(SKAction(named: "fadeOut")!)
                    for touch in touches {
                        self.position = touch.locationInNode(gameScene)
                    }
                }
            case .Dropping:
                break
            default:
                break
                
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let gameScene = self.parent as! GameScene
        if gameScene.nowNode == self {
            switch gameScene.state {
            case .Ready:
                if touches.count == 1 {
                    for touch in touches {
                        gameScene.lastTouchNodeLocation = position
                        gameScene.lastTouchLocation = touch.locationInNode(gameScene)
                        gameScene.updateRF()
                    }
                }
            case .Dropping:
                break
            default:
                break
            }
        }
        gameScene.enableMultiTouch()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        userInteractionEnabled = true
    }
    
}
