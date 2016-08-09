//
//  GameViewController.swift
//  Don't Drop Me!
//
//  Created by 高宇超 on 7/5/16.
//  Copyright (c) 2016 Yuchao. All rights reserved.
//

import UIKit
import SpriteKit

let showPhy = false
let showNodes = false
let scaleMode: SKSceneScaleMode = .AspectFit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if let scene = Home(fileNamed: "Home") {
            // Configure the view.
            let skView = self.view as! SKView

            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            skView.showsPhysics = showPhy
            skView.showsNodeCount = showNodes
            scene.scaleMode = scaleMode

            skView.presentScene(scene)
        }
    }

    override func shouldAutorotate() -> Bool {
        return false
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
