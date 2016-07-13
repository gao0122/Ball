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
        let gameScene = self.scene as! GameScene
        switch gameScene.state {
        case .Ready:
            if touches.count == 1 {
                gameScene.nowNode = self.parent!
                gameScene.rotationNode.hidden = true
                gameScene.functionNode.hidden = true
            }
        case .Dropping:
            break
        default:
            break
            
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let gameScene = self.scene as! GameScene
        if gameScene.nowNode == self.parent! {
            switch gameScene.state {
            case .Ready:
                if touches.count == 1 {
                    gameScene.disableMultiTouch()
                    for touch in touches {
                        // self.parent!.parent!.parent is the SKReferenceNode in GameScene
                        self.parent!.position = touch.locationInNode(self.parent!.parent!)
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
        let gameScene = self.scene as! GameScene
        if gameScene.nowNode == self.parent! {
            switch gameScene.state {
            case .Ready:
                if touches.count == 1 {
                    for touch in touches {
                        gameScene.lastTouchNodeLocation = self.parent!.position
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