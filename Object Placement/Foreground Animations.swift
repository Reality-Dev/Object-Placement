//
//  UIView.swift
//  Hello Augmented World
//
//  Created by Grant Jarvis on 7/26/20.
//
import UIKit
import GLKit


class foreground : UIImageView {
    
    var friend : foreground!
    
    func runFaceLogoAnimation(friend: foreground, controller: TransitionViewController){
        self.friend = friend
        UIView.animate(withDuration: 0.75, animations: {
                self.transform = self.transform.rotated(by: CGFloat(GLKMathDegreesToRadians(180)))
                self.transform = self.transform.rotated(by: CGFloat(GLKMathDegreesToRadians(180)))
              },  completion: { finished in
                  if finished {
                    self.fadeOutForeground(controller: controller)
                    self.friend.fadeOutForeground(controller: nil)
                      }
                  })
    }
    
    
    func fadeOutForeground(controller: TransitionViewController?) {
        UIView.animate(withDuration: 0.75, animations: {
            self.alpha = 0.0
        },  completion: { finished in
            if finished {
                self.removeFromSuperview()
                if controller != nil{
                    controller?.performSegue(withIdentifier: "toARView", sender: nil)
                    }
                }
            })
    }
}
