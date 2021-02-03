//
//  FocusCircle.swift
//  Hello Augmented World
//
//  Created by Grant Jarvis on 7/28/20.
//

import RealityKit
import Combine
import GLKit




extension Entity {

    ///From Reality Composer, the visible ModelEntities are children of nonVisible Entities
    ///Recursively searches through all descendants for a ModelEntity, Not just through the direct children.
    ///Reutrns the first model entity it finds.
    ///Returns the input entity if it is a model entity.
    func findModelEntity() -> ModelEntity? {
        if self is HasModel { return self as? ModelEntity }
        
        guard let modelEntities = self.children.filter({$0 is HasModel}) as? [ModelEntity] else {return nil}
        
        if !(modelEntities.isEmpty) { //it's Not empty. We found at least one modelEntity.
            
            return modelEntities[0]
            
        } else { //it is empty. We did Not find a modelEntity.
            //every time we check a child, we also iterate through its children if our result is still nil.
            for child in self.children{

                if let result = child.findModelEntity(){
                    return result
                }}}
        return nil //default
    }
    
    func installTranslationGestures(view: ARView, size: Float){
        let modelEntity = self.findModelEntity()
        let bounds = modelEntity?.model?.mesh.bounds.extents
        let largerTargetSize = (bounds ?? [0,0,0]) * size
        //Some people might want the finger target to be larger than the actual object to make it easier to press.
        let newShape = ShapeResource.generateBox(size: largerTargetSize)
        let newCollisionComponent = CollisionComponent.init(shapes: [newShape])
        modelEntity?.components.set(newCollisionComponent)
        view.installGestures(.all, for: modelEntity!)
    }
    
}








