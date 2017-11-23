//
//  ViewController.swift
//  PaddingtonCatch
//
//  Created by Marco Vidaurre on 10/11/17.
//  Copyright © 2017 Marco Vidaurre. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Foundation

//__ Use this extension to clamp the vslues of the toss velocity.
extension Comparable
{
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate
{
    
    
    @IBOutlet weak var sceneView:   ARSCNView!
    @IBOutlet weak var playButton:  UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    
    let session = ARSession()
    let sessionConfiguration = ARWorldTrackingConfiguration()
    
    let gameStateInPlay:Bool = false


    var sandArr = [VirtualObject]()
    var planes = [String: VirtualObject]()
    // This node basically returns info about the camera
    let cameraConfig = CameraConfig()
    
    struct CollisionTypes : OptionSet
    {
        let rawValue: Int
        static let bottom  = CollisionTypes(rawValue: 1 << 0)
        static let shape = CollisionTypes(rawValue: 1 << 1)
    }
    
    @IBAction func resetButton(_ sender: Any)
    {
        resetGame()
    }
    
    //__ init the game if the play button is pressed.
    @IBAction func playButton(_ sender: Any)
    {
        if(!gameStateInPlay){ initGame() }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints] //, ARSCNDebugOptions.showWorldOrigin]
        
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        
        //__Set up a new scene
        setupScene()
        //__ Set up physics
        setupPhysics()
        
        
        //__ Create tap gesture recognizer
        let tapSandwichGesture = UITapGestureRecognizer(target: self,
                                                        action:#selector(handleSandwichTap(sender:)))
        self.sceneView.addGestureRecognizer(tapSandwichGesture)
        
        // Create pan gesture recognizer
        let tossSandwichGesture = UIPanGestureRecognizer(target: self,
                                                         action: #selector(handleSandwichToss(sender:)))
        self.sceneView.addGestureRecognizer(tossSandwichGesture)
    
        
    }
    
    //__Reset the game
    func resetGame()
    {
        playButton.isHidden = false
    }
    
    func loadModel()
    {
        let dir = calculateCameraDirection(cameraNode: cameraConfig.cameraNode)
        let pos = pointInFrontOfPoint(point: SCNVector3Make(0, -0.15, 0), direction: dir, distance: 0.4)
        let sandwichObj = VirtualObject(name: "sandwich")
        sandwichObj.loadModel(withName:"marmalade_sandwich.scn" )
        sandwichObj.position = pos
        sandwichObj.orientation = cameraConfig.cameraNode.orientation
        sceneView.pointOfView?.addChildNode(sandwichObj)

    }
    //__Start a new game of Paddington Catch.
    func initGame ()
    {
        playButton.isHidden = true
        //__Load all of the sandwiches. This should only be done once.
        sandArr.removeAll()
        self.loadModel()
    }
    

    func setupScene()
    {
        //set the view's delegate to tell our sceneView that this class is its delegate
        sceneView.delegate = self
        //set the session
        sceneView.session = session
        //Enables multisample antialiasing with four samples per screen pixel.
        //Renders each pixel multiple times and combines the results
        sceneView.antialiasingMode = .multisampling4X
        // disable lights updating.
        sceneView.automaticallyUpdatesLighting = false
        // disable the default lighting in order to update the lights depending on the object's position
        sceneView.autoenablesDefaultLighting = false
        sceneView.preferredFramesPerSecond = 60
        sceneView.contentScaleFactor = 1.3
        cameraConfig.initCam(sceneView: sceneView)
        cameraConfig.configureDisplay(sceneView: sceneView)
    }
    
    func setupPhysics()
    {
        // Use a huge size to cover the entire world
        let bottomPlane = SCNBox(width: 10000, height: 1.0, length: 10000, chamferRadius: 0)
        
        // Use a clear material so the body is not visible
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        bottomPlane.materials = [material]
        
        // Position 10 meters below the floor
        let bottomNode = SCNNode(geometry: bottomPlane)
        bottomNode.position = SCNVector3(x: 0, y: -10, z: 0)
        
        // Apply kinematic physics, and collide with shape categories
        let physicsBody = SCNPhysicsBody.static()
        physicsBody.categoryBitMask = CollisionTypes.bottom.rawValue
        physicsBody.contactTestBitMask = CollisionTypes.shape.rawValue
        bottomNode.physicsBody = physicsBody
        
        self.sceneView.scene.rootNode.addChildNode(bottomNode)
        
        self.sceneView.scene.physicsWorld.contactDelegate = self

    }



    @objc func handleSandwichTap(sender: UITapGestureRecognizer)
    {
        let tapPoint = sender.location(in: sceneView)
        guard let hit=sceneView.hitTest(tapPoint, options: nil).first else { return }
        let hitTest = sceneView.hitTest(tapPoint)
        if hitTest.isEmpty
        {
            print("didn't touch anything")
        } else
        {
            let node = hit.node
            if (node.name?.range(of:"sand") != nil)
            {
                print(hit.node.parent!.parent!.name!)
            }
        }
    }
    
    @objc func handleSandwichToss(sender: UIPanGestureRecognizer)
    {
        let velocity = sender.velocity(in: sceneView)
        let translate = sender.translation(in: sceneView)
        let tapPoint:CGPoint
        var node:SCNNode = SCNNode()
        var lastTranslate:CGPoint  = CGPoint(x:0.0, y:0.0)
        var prevTranslate:CGPoint  = CGPoint(x:0.0, y:0.0)
        var lastTime:TimeInterval = 0.0
        var prevTime:TimeInterval = 0.0
        if(sender.state == UIGestureRecognizerState.began)
        {
            tapPoint=sender.location(in: sceneView)
            guard let hit=sceneView.hitTest(tapPoint, options: nil).first else { return }
            node = hit.node
            
            if (node.name?.range(of:"sand") != nil)
            {
                if (node.parent!.parent! is VirtualObject)
                {
                    lastTime = NSDate.timeIntervalSinceReferenceDate
                    lastTranslate = translate;
                    prevTime = lastTime;
                    prevTranslate = lastTranslate;

                }
            }
        }
        if (sender.state == UIGestureRecognizerState.changed)
        {
            prevTime = lastTime
            prevTranslate = lastTranslate
            lastTime = NSDate.timeIntervalSinceReferenceDate
            lastTranslate = translate
            
        }
        if (sender.state == UIGestureRecognizerState.ended)
        {
            var swipeVelocity:CGPoint  = CGPoint(x:0.0, y:0.0)

            let seconds:TimeInterval = NSDate.timeIntervalSinceReferenceDate - prevTime;
            if (seconds>0.0)
            {
                swipeVelocity = CGPoint(x:Double((translate.x - prevTranslate.x))/seconds, y:Double((translate.y - prevTranslate.y))/seconds)
            }
            
            let direction = CGPoint(x:Double((translate.x - prevTranslate.x)), y:Double((translate.y - prevTranslate.y)))
            
            let magnitude = sqrt((swipeVelocity.x * swipeVelocity.x) + (swipeVelocity.y * swipeVelocity.y))

            let inertiaSeconds = 2.0;  // let's calculate where that flick would take us this far in the future
            let final:CGPoint = CGPoint(x:Double(translate.x + swipeVelocity.x) * inertiaSeconds,
                                        y:Double(translate.y + swipeVelocity.y) * inertiaSeconds)
            
            
            print("swipe velocity is  \(swipeVelocity)")
            print("magnitude of swipeVelocity is \(magnitude)")
            print("we end up at this point \(final)")
            print("direction \(direction)")
            /*
            var vo:VirtualObject = VirtualObject()
            vo = node.parent!.parent! as! VirtualObject
            vo.setUpPhysics()

            vo.physicsBody?.applyTorque(SCNVector4Make(1,0,0,Float(velocity.y/10000)),asImpulse: true)
            let finalvec = SCNVector3Make(Float(direction.x * swipeVelocity.x),
                                          Float(abs(direction.y) * swipeVelocity.y),
                                          -1.0)
            
            
            
             vo.physicsBody?.applyForce(SCNVector3Make(finalvec.x,
                                                       finalvec.y,
                                                       finalvec.z * 125),
                                                       asImpulse: true)
            */
            
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    {
        //____to detect planes
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        //____Create a SceneKit plane to visualize the node using its position and extent.
        let plane = SCNBox(width: CGFloat(planeAnchor.extent.x * 2), height: 0.005, length: CGFloat(planeAnchor.extent.z * 2), chamferRadius: 0)
        let planeNode = VirtualObject(name:"Floor")
        planeNode.createPlaneWith(geo: plane, node:node)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, -0.005, planeAnchor.center.z)
        //planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        node.addChildNode(planeNode)
        let key = planeAnchor.identifier.uuidString
        self.planes[key] = planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
    {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let key = planeAnchor.identifier.uuidString
        if let existingPlane = self.planes[key]
        {
            if let geo = existingPlane.geometry as? SCNBox
            {
                geo.width = CGFloat(planeAnchor.extent.x)
                geo.length = CGFloat(planeAnchor.extent.z)
            }
            existingPlane.position = SCNVector3Make(planeAnchor.center.x, -0.005, planeAnchor.center.z)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor)
    {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let key = planeAnchor.identifier.uuidString
        if let existingPlane = self.planes[key]
        {
            existingPlane.removeFromParentNode()
            self.planes.removeValue(forKey: key)
        }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
    {
        let lightEstimate = self.sceneView.session.currentFrame?.lightEstimate
        
        // If light estimation is enabled, update the intensity of the model's lights
        if lightEstimate != nil &&  sessionConfiguration.isLightEstimationEnabled
        {
            let intensity = (lightEstimate?.ambientIntensity)! / 40
            self.sceneView.scene.lightingEnvironment.intensity = intensity
        }
        else
        {
            self.sceneView.scene.lightingEnvironment.intensity = 25
        }
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        setSessionConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact)
    {
        let mask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        
        if CollisionTypes(rawValue: mask) == [CollisionTypes.bottom, CollisionTypes.shape]
        {
            if contact.nodeA.physicsBody!.categoryBitMask == CollisionTypes.bottom.rawValue
            {
                print("Removing node B \(contact.nodeB.name!)")
                contact.nodeB.removeFromParentNode()
                self.loadModel()

            }
            else
            {
                print("Removing node A \(contact.nodeA.name!)")
                contact.nodeA.removeFromParentNode()
            }
        }
    }
    
    func setSessionConfiguration()
    {
        // check if the device support the ar world
        if ARWorldTrackingConfiguration.isSupported
        {
            // Run the view's session
            sceneView.session.run(sessionConfiguration, options: [.resetTracking, .removeExistingAnchors])
            sessionConfiguration.isLightEstimationEnabled = true
            sessionConfiguration.planeDetection = .horizontal
            
        }
    }


   
    func session(_ session: ARSession, didFailWithError error: Error)
    {
        showSessionStateMessage(message: "Session failed with error \(error)")
    }
    
    func sessionWasInterrupted(_ session: ARSession)
    {
        showSessionStateMessage(message: "Session was interrupted")
    }
    
    func showSessionStateMessage(message sessionState: String)
    {
        let alert = UIAlertController(title: "Session State", message: sessionState, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func calculateCameraDirection(cameraNode: SCNNode) -> SCNVector3
    {
        let x = -cameraNode.rotation.x
        let y = -cameraNode.rotation.y
        let z = -cameraNode.rotation.z
        let w = cameraNode.rotation.w
        let cameraRotationMatrix = GLKMatrix3Make(cos(w) + pow(x, 2) * (1 - cos(w)),
                                                  x * y * (1 - cos(w)) - z * sin(w),
                                                  x * z * (1 - cos(w)) + y*sin(w),
                                                  
                                                  y*x*(1-cos(w)) + z*sin(w),
                                                  cos(w) + pow(y, 2) * (1 - cos(w)),
                                                  y*z*(1-cos(w)) - x*sin(w),
                                                  
                                                  z*x*(1 - cos(w)) - y*sin(w),
                                                  z*y*(1 - cos(w)) + x*sin(w),
                                                  cos(w) + pow(z, 2) * ( 1 - cos(w)))
        
        let cameraDirection = GLKMatrix3MultiplyVector3(cameraRotationMatrix, GLKVector3Make(0.0, 0.0, -1.0))
        return SCNVector3FromGLKVector3(cameraDirection)
    }
    
    func pointInFrontOfPoint(point: SCNVector3, direction: SCNVector3, distance: Float) -> SCNVector3
    {
        var x = Float()
        var y = Float()
        var z = Float()
        
        x = point.x + distance * direction.x
        y = point.y + distance * direction.y
        z = point.z + distance * direction.z
        
        let result = SCNVector3Make(x, y, z)
        return result
    }

}

//__ Uses this function as shorthand to add 2 Vectors together
func +(left: SCNVector3, right: SCNVector3) -> SCNVector3
{
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
