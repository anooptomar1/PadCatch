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
    
    //__ These are the planes used to collided with the marmalade sandwiches
    func createPlaneWith(geo:SCNBox)
    {
        self.geometry=geo
        let mat = SCNMaterial()
        let img = UIImage(named: "art.scnassets/tron/tron-albedo.png")
        mat.diffuse.contents = img
        mat.diffuse.wrapS = SCNWrapMode.repeat
        mat.diffuse.wrapT = SCNWrapMode.repeat
        self.geometry?.materials = [mat]
        
        //geo.firstMaterial?.diffuse.contents = UIColor.blue

        let body = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: geo, options: nil))
        body.categoryBitMask = CollisionTypes.bottom.rawValue
        body.contactTestBitMask = CollisionTypes.shape.rawValue

        //body.restitution = 1.0
        //body.friction = 1.0
        self.physicsBody = body
    }
    
    //__ Set up the physics body we will use to toss the sandwich
    func setUpPhysics()
    {
        if(self.physicsBody==nil)
        {
            //__ Sandwich
            let body = SCNPhysicsBody(type: .dynamic  , shape: SCNPhysicsShape(node: self))
            body.categoryBitMask = CollisionTypes.shape.rawValue
            body.contactTestBitMask = CollisionTypes.bottom.rawValue
            body.mass = 0.5
            body.damping = 0.5
            //body.friction = 1.0
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
    
    func unLoadModel()
    {
        isPlaced = false
        self.removeFromParentNode()

    }
    
    /// Returns a `VirtualObject` if one exists as an ancestor to the provided node.
    /*
    static func existingObjectContainingNode(_ node: SCNNode) -> VirtualObject?
    {
        if let virtualObjectRoot = node as? VirtualObject
        {
            return virtualObjectRoot
        }
        
        guard let parent = node.parent.parent as! VirtualObject else { return nil }
        
        // Recurse up to check if the parent is a `VirtualObject`.
        return existingObjectContainingNode(parent)
    }
    */
}



