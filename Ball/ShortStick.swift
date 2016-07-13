//
//  ShortStick.swift
//  Ball
//
//  Created by 高宇超 on 7/9/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit

class ShortStick: TheObjects {
    
    let objName = "Short stick"
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        userInteractionEnabled = true
    }
    
}