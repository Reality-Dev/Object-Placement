//
//  ViewController.swift
//  Hello Augmented World
//
//  Created by Grant Jarvis on 7/20/20.
//

import UIKit
import RealityKit
import ARKit
import GLKit
import Combine
import Accelerate
import CoreHaptics

class ViewController: UIViewController, ARSessionDelegate {
    

    
    @IBOutlet weak var arView: ARView!
    
    
    var pointAnchor : AnchorEntity!
        
    var 📦 : Experience.Box!
    
    var poolBallTest : PoolBallTest.BallScene!
    
    var sphere : ModelEntity!
    
    var helloTextEntity : ModelEntity!
    
    var FCNoSurface : ModelEntity!
    var FCSurface : ModelEntity!
    
    var ball14TempTranslucent : Entity!
    var ball14Opaque : Entity!
    var ball14Translucent : Entity!
    var beacon : Entity!
    
    var focusCircle : FocusCircle!
    
    //var 🌟 : ARTrackedRaycast?
    
    let pointEntity = Entity()
    var circleTarget : simd_float3 = [0,0,0]
    var multiple = simd_quatf(angle: (-.pi / 2), axis: [1,0,0]) * simd_quatf(angle: (-.pi), axis: [0,1,0])
    
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
        case canPlaceInScene
        
        ///Hovering ball from center-screen to center of focus circle.
        case FadingInScene
        
        ///Moving focus circle around, with Horizontal and Vertical states.
        ///Tap to place object (if Horizontal).
        case settingFocusCircle
        
        ///Fading in entity where it was located on top of the focus circle when you tapped.
        case placingEntityAtLocation
        
        ///Entity has made it to its destination and is done fading in.
        case entityIsPlaced
        
    
    }
    
    

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //arView.isHidden = true
        // Create & configure the engine before doing anything else, since the game begins immediately.
        createAndStartHapticEngine()
        
        faceIsDoneSpinning()
    }
    
    
    func faceIsDoneSpinning(){
//        let config = ARWorldTrackingConfiguration()
//        config.isLightEstimationEnabled = false
//        self.arView?.session.run(config)
        //arView.isHidden = false
        arView.session.delegate = self
        
        loadPoolBalls()
        
        arView.renderOptions.insert(.disableMotionBlur)
        arView.renderOptions.insert(.disableAREnvironmentLighting)
        
        self.sceneState = .canPlaceInScene
    }
    

    func olderStuff(){
        // Load the "Box" scene from the "Experience" Reality File
        loadSceneAsync()
    }
       

    func loadSceneAsync(){
        Experience.loadBoxAsync(completion: { completion in
            do{
                self.📦 = try completion.get()
            } catch {
                print("could Not load Box Scene")
                return
            }
            self.boxSceneLoaded()
        })
    }
    
    func boxSceneLoaded(){
        // Add the box anchor to the scene
        arView.scene.anchors.append(📦)
        

        makeText()

        makeSphere()

        📦.ball14?.installTranslationGestures(view: self.arView, size: 1.5)
        📦.steelBox?.installTranslationGestures(view: self.arView, size: 1.5)
        addTapRecognizer()
    }
    

  
    
    

    
    
    
    
    
    
    
    
    func loadPoolBalls(){
        
        poolBallTest = try! PoolBallTest.loadBallScene()
        arView.scene.addAnchor(poolBallTest)
        
        ball14Opaque = poolBallTest.ball14Opaque!
        pointAnchor = AnchorEntity()
        arView.scene.addAnchor(pointAnchor)
        ball14Translucent = poolBallTest.ball14Translucent!
        ball14TempTranslucent = ball14Translucent.clone(recursive: true)
        pointAnchor.addChild(ball14TempTranslucent)
        //
        beacon = poolBallTest.beacon!
        
        
        
        poolBallTest.actions.sceneStarted.onAction = { entity in
            print("SCENE STARTED")
            if self.sceneState == .canPlaceInScene {
                self.putBallInScene()
            }
        }
        
        let sceneFocusCircle = poolBallTest.focusCircle
        let FCNoSurfaceParent = sceneFocusCircle?.findEntity(named: "FCNoSurface")
        FCNoSurface = FCNoSurfaceParent?.recursiveAllDescendants()
        FCNoSurface.name = "FCNoSurface"
        //sceneFocusCircle?.transform = FCNoSurface.transform
        let FCSurfaceParent = sceneFocusCircle?.findEntity(named: "FCSurface")
        FCSurface = FCSurfaceParent?.recursiveAllDescendants()
        FCSurface.name = "FCSurface"
        
        
        
    }
    
    
    
    

        
    func showAnchor(anchor: ARPlaneAnchor){
        
        let material = SimpleMaterial.init(color: .blue, isMetallic: false)
        let mesh = MeshResource.generateBox(width: anchor.extent.x, height: 0.007, depth: anchor.extent.z)
        let planeModel = ModelEntity(mesh: mesh, materials: [material])
        planeModel.transform = Transform(matrix: anchor.transform)
        poolBallTest.addChild(planeModel, preservingWorldTransform: true)
    }
    
    


    
    
    
    func placeBall(){
        sceneState = .placingEntityAtLocation
        ball14Opaque.setParent(focusCircle.parent, preservingWorldTransform: true)
        ball14Translucent.setParent(focusCircle.parent, preservingWorldTransform: true)
        ball14Opaque.transform = ball14Translucent.transform
        ball14Translucent.scale += [0.001, 0.001, 0.001]
        self.poolBallTest.notifications.showChildBall.post()
        self.poolBallTest.notifications.hideParentBall.post()
        self.focusCircle.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9){
            //show animation takes 0.75 sec as of this writing.
            self.ball14Translucent.removeFromParent()
            self.sceneState = .entityIsPlaced
            self.ball14Opaque.installTranslationGestures(view: self.arView, size: 3)
            self.olderStuff()
            self.arView.renderOptions.remove(.disableAREnvironmentLighting)
        }
        
    }
    

    
    
    

    
    
    
    
  
    
    
    
    //installTranslationGestures() is on the Entity Extension.
    func addTapRecognizer(){
        arView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(handleTap(recognizer:))))
    }
    
        @objc func handleTap(recognizer: UITapGestureRecognizer){
            let newBox = (📦.steelBox?.clone(recursive: true))!
            let tapLocation = recognizer.location(in: arView)
            let raycastResults = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            guard !raycastResults.isEmpty else {return}
            📦.addChild(newBox)
            newBox.installTranslationGestures(view: arView, size: 1.3)
            let newTransform = Transform(matrix: raycastResults.first!.worldTransform)
            newBox.setPosition(newTransform.translation, relativeTo: nil)
        }
    
    
    
    func makeText(){
        helloTextEntity = ModelEntity()
        
        let helloTextMesh = MeshResource.generateText("Hello World",
                                          extrusionDepth: 0.01,
                                          font: UIFont.init(name: "Helvetica", size: 0.1)!,
                                          containerFrame: CGRect.zero,
                                          alignment: .natural,
                                          lineBreakMode: .byTruncatingTail)
        
        let helloTextMaterial = SimpleMaterial.init(color: .blue, isMetallic: true)
        let helloTextModel = ModelComponent(mesh: helloTextMesh, materials: [helloTextMaterial])
        helloTextEntity.model = helloTextModel
        
        📦.addChild(helloTextEntity)
        
        
        //Its get/set position relative to its parent, which is the boxAnchor
        //a vector 3
        helloTextEntity.position = makeTextAdjustment(textModelEntity: helloTextEntity, position: [0,0.3,0])
        //helloTextEntity.installTranslationGestures(view: self.arView, size: 2)
    }
    
    
    func makeTextAdjustment(textModelEntity: ModelEntity, position: SIMD3<Float>) -> SIMD3<Float>{
        let bounds = textModelEntity.model?.mesh.bounds
        let boxCenter = bounds?.center
        let boxMin = bounds?.min
        let xCompensation = boxCenter!.x - boxMin!.x
        let yCompensation = boxCenter!.y - boxMin!.y
        let zCompensation = boxCenter!.z - boxMin!.z //Not usually needed but it's fine.
        //center is curently at the bottom-left, so move the text to the left and down by 1/2 the size of its bounds
        return [position.x - xCompensation, position.y - yCompensation, position.z - zCompensation]
        

    }
    
    
    
    ///sets the position relative to the text's parent.
    public func setTextPosition(textModelEntity: ModelEntity, position: SIMD3<Float>, relativeTo referenceEntity: Entity){
        textModelEntity.setPosition(position, relativeTo: referenceEntity)
        let compensation = getCompensation(textModelEntity: textModelEntity)
        //in its own coordinate space, keeping its world-orientation
        textModelEntity.setPosition(compensation, relativeTo: textModelEntity)
    }
    
    public func convertPositionForText(textModelEntity: ModelEntity, position: SIMD3<Float>, relativeTo referenceEntity: Entity) -> SIMD3<Float>{
        let convertedPosition = textModelEntity.convert(position: position, from: referenceEntity)
        let compensation = getCompensation(textModelEntity: textModelEntity)
        let compensatedConvertedPosition  = convertedPosition - compensation
        let compensatedPosition = referenceEntity.convert(position: compensatedConvertedPosition, from: textModelEntity)
        return compensatedPosition
    }
    
    public func getCompensation(textModelEntity: ModelEntity) -> SIMD3<Float>{
        let bounds = textModelEntity.model?.mesh.bounds
        let boxCenter = bounds!.center
        let boxMin = bounds!.min
        let compensation = boxCenter - boxMin
        return compensation
    }
    
    
    
    
    
    func makeSphere(){
        let redMaterial = SimpleMaterial.init(color: .red, isMetallic: true)
//        let occlusionMaterial = OcclusionMaterial.init(receivesDynamicLighting: true)
//        let color = UIColor.clear
//        let newColor = color.withAlphaComponent(0.5)
//        let simpleMaterial = UnlitMaterial.init(color: newColor)
        sphere = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [redMaterial])
        📦.addChild(sphere)
        sphere.position = [0,0.3,0]
        //sphere.installTranslationGestures(view: self.arView, size: 2)
    }
    
}










