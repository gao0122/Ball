//
//  Bounce.swift
//  Don't Drop Me!
//
//  Created by 高宇超 on 7/7/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit

class Bounce: TheObjects {
    
    let objName = "Bounce"
    let kMin: CGFloat = 0.32
    let kMax: CGFloat = 0.84
    
    var k: CGFloat = 0.5
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        userInteractionEnabled = true
    }
    
}