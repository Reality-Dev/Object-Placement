//
//  FadeInExtension.swift
//  Hello Augmented World
//
//  Created by Grant Jarvis on 7/29/20.
//

import ARKit
import RealityKit
import FocusEntity

extension ViewController {
    
    
    ///A horizontal plane has been found.
    ///Move the pool ball to be on top of the focus circle.
    func moveBallToPlane(){
        arView.renderOptions.remove(.disableMotionBlur)
        makeHapticBump()
        
        //Make the focus circle.
            do {
              let onColor: MaterialColorParameter = try .texture(.load(named: "Close"))
              let offColor: MaterialColorParameter = try .texture(.load(named: "Open"))
              self.focusCircle = FocusEntity(
                on: self.arView,
                style: .colored(
                  onColor: onColor, offColor: onColor,
                  nonTrackingColor: offColor
                )
              )
            } catch {
                self.focusCircle = FocusEntity(on: self.arView, focus: .classic)
              print("Unable to load plane textures")
              print(error.localizedDescription)
            }
            self.focusCircle.setParent(self.poolBallScene, preservingWorldTransform: true)
        
        //Give the focus circle time to get into position.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            self.sceneState = .movingBallIntoPosition
            //setting focusCircle as the parent of ball14Translucent would allow focusCircle rotations to affect ball14Translucent while it is moving down to the surface.
            self.ball14Translucent.setParent(self.poolBallScene, preservingWorldTransform: true)
            self.ball14Opaque.setParent(self.focusCircle, preservingWorldTransform: false)
        }
    }
    
    
}
