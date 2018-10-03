//
//  MSButtonNode.swift
//  Make School
//
//  Created by Martin Walsh on 09/06/2016.
//  Copyright (c) 2016 Make School. All rights reserved.
//

import SpriteKit

enum MSButtonNodeState {
    case msButtonNodeStateActive, msButtonNodeStateSelected, msButtonNodeStateHidden
}

class MSButtonNode: SKSpriteNode {
    
    var clickable = true
    var longTouched = false
    
    /* Setup a dummy action closure */
    var selectedHandler: () -> Void = {
        print("No button action set")
    }
    
    /* Button state management */
    var state: MSButtonNodeState = .msButtonNodeStateActive {
        didSet {
            switch state {
            case .msButtonNodeStateActive:
                /* Enable touch */
                break
            case .msButtonNodeStateSelected:
                // become larger
                break
            default:
                break
            }
        }
    }
    
    /* Support for NSKeyedArchiver (loading objects from SK Scene Editor */
    required init?(coder aDecoder: NSCoder) {
        
        /* Call parent initializer e.g. SKSpriteNode */
        super.init(coder: aDecoder)
        
        /* Enable touch on button node */
        self.isUserInteractionEnabled = true
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        state = .msButtonNodeStateSelected
        clickable = true
        longTouched = false
        if let name = self.name {
            if name == "objIcon" || name == "tutorialIconLongPress" {
                if let scene = self.scene as? GameScene {
                    scene.objIconTouchBeganTime = touches.first!.timestamp
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        clickable = false
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if clickable {
            if !longTouched {
                if let scene = self.scene as? GameScene {
                    scene.objIconTouchBeganTime = nil
                }
                selectedHandler()
                state = .msButtonNodeStateActive
            }
        }
    }
    
    func objIconLongPress() -> Void {
        clickable = false
        if let scene = self.scene as? GameScene {
            if !scene.touched {
                if scene.state == .ready &&
                    (scene.tutorialState == .done || scene.tutorialState == .iconLongPress) {
                    // iconLongPressAction
                    scene.nowNode.run(SKAction(named: "moveToCenter")!)
                    scene.lastTouchNodeLocation = CGPoint(x: screenWidth / 2, y: 384)
                    let scale = SKAction.afterDelay(0.4, performAction: SKAction(named: "scaleToFocus")!)
                    scale.timingMode = SKActionTimingMode.easeInEaseOut
                    scene.nowNode.run(scale)
                    scene.longPressObjIconUpdateRF = true
                    
                    if scene.functionNode.alpha != 0 {
                        scene.functionNode.run(SKAction(named: "fadeOut")!)
                    }
                    if scene.rotationNode.alpha != 0 {
                        scene.rotationNode.run(SKAction(named: "fadeOut")!)
                    }
                    
                    if scene.tutorialState == .iconLongPress {
                        scene.tutorialLayerBg?.run(SKAction.fadeOut(withDuration: 0.32))
                        scene.popLastTutorialState()
                    }
                }
            }
            scene.touched = false
            longTouched = false
        }   
    }
    
}
