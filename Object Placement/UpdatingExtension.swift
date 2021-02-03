//
//  UpdatingExtension.swift
//  Hello Augmented World
//
//  Created by Grant Jarvis on 7/29/20.
//


import ARKit
import RealityKit

extension ViewController {

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch sceneState {
            case .movingBallIntoPosition:
                movingBallIntoPosition()
            case .findingPlacementOnPlane:
                //Make beacon and visible ball invisible whenever focus entity is Not located on a plane.
                ball14Translucent.isEnabled = focusCircle.onPlane
                beacon.isEnabled = focusCircle.onPlane
            default:
                break
        }
    }
    
    ///Move ball from in front of camera to be placed on top of focus circle.
    func movingBallIntoPosition(){
        guard focusCircle != nil else {return}
            let translucentBallPosition = ball14Translucent.position(relativeTo: nil)
            let difference = focusCircle.position(relativeTo: nil) - translucentBallPosition
            let newPosition = translucentBallPosition + (normalize(difference) * 0.01)
            let differenceMagnitude = simd_length(difference)
        
            ball14Translucent.setPosition(newPosition, relativeTo: nil)
        
            if differenceMagnitude <= 0.01 {
                doneMovingIntoPlace()
        }}
    
    
    func doneMovingIntoPlace(){
        ball14Translucent.setParent(focusCircle, preservingWorldTransform: true)
        self.sceneState = .findingPlacementOnPlane
        beacon.isEnabled = true
        self.focusCircle.addChild(self.beacon)
        //keep the beacon from occluding the focus circle.
        self.beacon.position = [0,0.005,0]
        self.beacon.setScale([1,0.1,1], relativeTo: focusCircle)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if sceneState == .findingPlacementOnPlane &&
            focusCircle.onPlane {
            placeBall()
            makeHapticBump()
        } else if sceneState == .entityIsPlaced{
            makeHapticBump()
        }
    }

    
    
    


}
