//
//  MSButtonNode.swift
//  Make School
//
//  Created by Martin Walsh on 09/06/2016.
//  Copyright (c) 2016 Make School. All rights reserved.
//

import SpriteKit

enum MSButtonNodeState {
    case MSButtonNodeStateActive, MSButtonNodeStateSelected, MSButtonNodeStateHidden
}

class MSButtonNode: SKSpriteNode {
    
    var clickable = true
    var longTouched = false
    
    /* Setup a dummy action closure */
    var selectedHandler: () -> Void = {
        print("No button action set")
    }
    
    /* Button state management */
    var state: MSButtonNodeState = .MSButtonNodeStateActive {
        didSet {
            switch state {
            case .MSButtonNodeStateActive:
                /* Enable touch */
                self.userInteractionEnabled = true
                
                /* Visible */
                self.alpha = 1
                break
            case .MSButtonNodeStateSelected:
                // become larger

                break
            case .MSButtonNodeStateHidden:
                /* Disable touch */
                self.userInteractionEnabled = false
                
                /* Hide */
                self.alpha = 0
                break
            }
        }
    }
    
    /* Support for NSKeyedArchiver (loading objects from SK Scene Editor */
    required init?(coder aDecoder: NSCoder) {
        
        /* Call parent initializer e.g. SKSpriteNode */
        super.init(coder: aDecoder)
        
        /* Enable touch on button node */
        self.userInteractionEnabled = true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        state = .MSButtonNodeStateSelected
        clickable = true
        longTouched = false
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        clickable = false
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if clickable {
            selectedHandler()
            state = .MSButtonNodeStateActive
        }
    }

    func objIconLongPress(sender: UILongPressGestureRecognizer) -> Void {
        clickable = false
        if !longTouched {
            if let scene = self.scene as? GameScene {
                if !scene.touched {
                    // iconLongPressAction
                    scene.nowNode.runAction(SKAction(named: "scaleToFocus")!)
                }
                scene.touched = false
            }
            longTouched = true
        }
    }
    
}
