//
//  VirtualObject.swift
//  ARKitPoc
//
//  Created by AppFoundry on 13/06/2017.
//  Copyright © 2017 AppFoundry. All rights reserved.
//

import SceneKit

class VirtualObject: SCNNode
{
    
    var isPlaced: Bool = false
    struct CollisionTypes : OptionSet
    
    {
        let rawValue: Int
        static let bottom  = CollisionTypes(rawValue: 1 << 0)
        static let shape = CollisionTypes(rawValue: 1 << 1)
    }
    
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
    
    func createPlaneWith(geo:SCNBox, node:SCNNode)
    {
        self.geometry=geo
        let mat = SCNMaterial()
        let img = UIImage(named: "art.scnassets/tron/tron-albedo.png")
        mat.diffuse.contents = img
        self.geometry?.materials = [mat]
        let body = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: geo, options: nil))
        body.categoryBitMask = CollisionTypes.bottom.rawValue
        body.contactTestBitMask = CollisionTypes.shape.rawValue

        body.restitution = 0.0
        body.friction = 1.0
        self.physicsBody = body
    }
    
    //__ Set up the physics body we will use to toss the sandwich
    func setUpPhysics()
    {
        if(self.physicsBody==nil)
        {
            //__ Sandwich
            print("Set physics on \(self.name!)")
            let body = SCNPhysicsBody(type: .dynamic  , shape: SCNPhysicsShape(node: self))
            body.categoryBitMask = CollisionTypes.shape.rawValue
            body.contactTestBitMask = CollisionTypes.bottom.rawValue
            body.mass = 0.05
            body.restitution = 0.25
            body.friction = 0.75
            self.physicsBody = body
        }
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


