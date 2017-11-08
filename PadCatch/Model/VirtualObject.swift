//
//  VirtualObject.swift
//  ARKitPoc
//
//  Created by AppFoundry on 13/06/2017.
//  Copyright © 2017 AppFoundry. All rights reserved.
//

import SceneKit

class VirtualObject: SCNNode {
    
    var isPlaced: Bool = false
    
    override init()
    {
        super.init()
    }
    
    init(name objectName: String)
    {
        super.init()
        self.name = objectName
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createPlaneWith(geo:SCNPlane)
    {
        self.geometry=geo
        let mat = SCNMaterial()
        let img = UIImage(named: "art.scnassets/tron/tron-albedo.png")
        mat.diffuse.contents = img
        self.geometry?.materials = [mat]
        
    }
    
    //__ Set up the physics body we will use to toss the sandwich
    func setUpPhysics()
    {
        //__ Sandwich
        let body = SCNPhysicsBody(type: .kinematic  , shape: SCNPhysicsShape(node: self))
        body.categoryBitMask = 1 << 1
        self.physicsBody = body
        //self.physicsBody?.isAffectedByGravity=false
        //self.physicsBody?.resetTransform()
    }
    
    func loadModel(withName:String)
    {
        guard let virtualObject = SCNScene(named: withName, inDirectory: "art.scnassets", options: nil) else { print("\(withName) not found");return }
        // Create a wrapper node that will be the parent of our scenes children.
        let wrapperNode = SCNNode()
        wrapperNode.name = "wrapperNode_\(self.name!)"
        // parent scene objects to wrapper
        for child in virtualObject.rootNode.childNodes
        {
            wrapperNode.addChildNode(child)
        }
        // Make the wrapper node a child of this instance
        self.addChildNode(wrapperNode)
        isPlaced = true
    }
    
    func unLoadModel(child: SCNNode)
    {
        child.removeFromParentNode()
        isPlaced = false
    }
}


