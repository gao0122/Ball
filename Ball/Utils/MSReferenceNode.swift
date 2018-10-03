//
//  MSPhysicsNode.swift
//  Make School
//
//  Created by Martin Walsh on 15/03/2016.
//  Copyright © 2016 Martin Walsh. All rights reserved.
//

import SpriteKit

class MSReferenceNode: SKReferenceNode {
    
    /* Avatar node connection */
    var obj: SKSpriteNode!
    
    override func didLoad(_ node: SKNode?) {
        
        /* Set reference to avatar node */
        obj = childNode(withName: "//obj") as! SKSpriteNode
    }
}
