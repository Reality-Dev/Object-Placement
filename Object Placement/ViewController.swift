//
//  ViewController.swift
//  Hello Augmented World
//
//  Created by Grant Jarvis on 7/20/20.
//

import RealityKit
import ARKit
import CoreHaptics
import FocusEntity

class ViewController: UIViewController, ARSessionDelegate {
    

    
    @IBOutlet weak var arView: ARView!
        
    var cameraAnchor : AnchorEntity!
    
    var poolBallScene : PoolBallProj.BallScene!
    
    var ball14Opaque : Entity!
    var ball14Translucent : Entity!
    var beacon : Entity!
    
    var focusCircle : FocusEntity!

    
    // Haptic Engine & State:
    public var engine: CHHapticEngine!
    public var engineNeedsStart = true
    lazy var supportsHaptics: Bool = {
        return (UIApplication.shared.delegate as? AppDelegate)?.supportsHaptics ?? false
    }()
    public var foregroundToken: NSObjectProtocol?
    public var backgroundToken: NSObjectProtocol?
    

    var sceneState : State = .loadingAppView {
        didSet {
            print("sceneState is now:", sceneState)
        }
    }
    

    indirect enum State: Equatable {

        ///ARView has Not yet loaded
        case loadingAppView
        
        ///Has Not yet found an ARPlaneAnchor
        case searchingForPlanes
        
        ///Hovering ball from center-screen to center of focus circle.
        case movingBallIntoPosition
        
        ///Moving focus circle around, with Horizontal and Vertical states.
        ///Tap to place object (if on plane).
        case findingPlacementOnPlane
        
        ///Fading in entity where it was located on top of the focus circle when the user tapped.
        case placingEntityAtLocation
        
        ///Entity has made it to its destination and is done fading in.
        case entityIsPlaced
    }
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Create & configure the engine before doing anything else, since the game begins immediately.
        createAndStartHapticEngine()
        arView.session.delegate = self
        
        
        //.disableGroundingShadows keeps the ground from occluding the focus circle.
        arView.renderOptions = [.disableMotionBlur,
                                .disableAREnvironmentLighting,
                                .disableGroundingShadows]
        
        self.sceneState = .searchingForPlanes
        loadPoolBalls()
    }
    


    
    func loadPoolBalls(){
        poolBallScene = try! PoolBallProj.loadBallScene()
        arView.scene.addAnchor(poolBallScene)

        ball14Opaque = poolBallScene.ball14Opaque!
        //ball14Opaque should Not be visible until the sceneState is .placingEntityAtLocation.
        ball14Opaque.isEnabled = false
        cameraAnchor = AnchorEntity(.camera)
        arView.scene.addAnchor(cameraAnchor)
        ball14Translucent = poolBallScene.ball14Translucent!
        cameraAnchor.addChild(ball14Translucent)
        ball14Translucent.position = [0,0,-0.3]
        beacon = poolBallScene.beacon!
        //beacon should Not be visible until the sceneState is .findingPlacementOnPlane.
        beacon.isEnabled = false
        
        poolBallScene.actions.sceneStarted.onAction = { entity in
                self.moveBallToPlane()
        }
    }
    
    
    
    ///The user tapped to place the entity at this location.
    func placeBall(){
        sceneState = .placingEntityAtLocation
        ball14Opaque.setParent(poolBallScene, preservingWorldTransform: true)
        ball14Translucent.setParent(poolBallScene, preservingWorldTransform: true)
        ball14Opaque.transform = ball14Translucent.transform
        //expand translucent ball slightly to avoid overlapping mesh issues.
        ball14Translucent.scale += [0.001, 0.001, 0.001]
        self.focusCircle.isEnabled = false
        //This closure will be called when the "showChildBall" behavior is completed.
        self.poolBallScene.actions.ballIsOpaque.onAction = { entity in
            self.ball14Translucent.removeFromParent()
            self.sceneState = .entityIsPlaced
            self.ball14Opaque.installTranslationGestures(view: self.arView, size: 3)
            self.arView.renderOptions.remove(.disableAREnvironmentLighting)
        }
        self.poolBallScene.notifications.showChildBall.post()
    }
}










