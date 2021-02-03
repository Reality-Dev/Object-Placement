//
//  TransitionViewController.swift
//  Hello Augmented World
//
//  Created by Grant Jarvis on 7/25/20.
//

import UIKit


class TransitionViewController: UIViewController {
    
    
    @IBOutlet weak var background: foreground!
    
    @IBOutlet weak var faceLogo: foreground!
    
    
    override func viewDidAppear(_ animated: Bool){
        super.viewDidAppear(animated)
        
        faceLogo.runFaceLogoAnimation(friend: background, controller: self)

    }
    

    
    
    
    
}
