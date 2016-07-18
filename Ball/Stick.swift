//
//  Stick.swift
//  Ball
//
//  Created by 高宇超 on 7/11/16.
//  Copyright © 2016 Yuchao. All rights reserved.
//

import SpriteKit

class Stick: TheObjects {
    
    let objName = "Stick"
    
    let lenMin: CGFloat = 0.5
    let lenMax: CGFloat = 2
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        userInteractionEnabled = true
    }
    
}