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


class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate
{
    
    
    @IBOutlet weak var sceneView:   ARSCNView!
    @IBOutlet weak var playButton:  UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    
    let session = ARSession()
    let sessionConfiguration = ARWorldTrackingConfiguration()
    
    let gameStateInPlay:Bool = false


    var sandArr = [VirtualObject]()
    
    // This node basically returns info about the camera
    let cameraConfig = CameraConfig()
    
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
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Create a new scene
        setupScene()
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
    
    //__Start a new game of Paddington Catch.
    func initGame ()
    {
        playButton.isHidden = true
        
        //__Load all of the sandwiches. This should only be done once.
        sandArr.removeAll()
        let dir = calculateCameraDirection(cameraNode: cameraConfig.cameraNode)
        let pos = pointInFrontOfPoint(point: SCNVector3Make(0, 0, 1), direction: dir, distance: 0.5)

        for s in 1...5
        {

            let sandwichObj = VirtualObject(name: "sandwich\(s)")
            sandwichObj.loadModel(withName:"marmalade_sandwich.scn" )
            sandwichObj.position = pos
            sandwichObj.orientation = cameraConfig.cameraNode.orientation

            //__ set up physics for this sandwich
            sandwichObj.setUpPhysics()
            // Hide all sandwiches except the first one
            if(!sandwichObj.isHidden && s>1)
            {
                print("Hiding \(sandwichObj)")
                sandwichObj.isHidden=true
            }
            // Add the sandwich to the camera as a child node
            sceneView.scene.rootNode.addChildNode(sandwichObj)
            //sceneView.pointOfView?.addChildNode(sandwichObj)
            //sandArr.append(sandwichObj)
        }
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
        self.sceneView.scene.physicsWorld.contactDelegate = self
 
        //__bottom plane
        /*
        let bottomPlane = SCNBox(width: 1, height: 0.5, length: 1, chamferRadius: 0)
        let bottomPlaneMat = SCNMaterial()
        let bottomPlaneNode = SCNNode(geometry: bottomPlane)
        let img = UIImage(named: "art.scnassets/sculptedfloorboards/sculptedfloorboards-albedo.png")
        //bottomPlaneMat.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        bottomPlaneMat.diffuse.contents = img
        bottomPlane.firstMaterial = bottomPlaneMat

        // Place it way below the world origin to catch all falling cubes
        bottomPlaneNode.position = SCNVector3Make(0, -1.0, 0)
        bottomPlaneNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        bottomPlaneNode.physicsBody!.categoryBitMask = 1 << 0
        bottomPlaneNode.physicsBody!.contactTestBitMask = 1 << 1
        self.sceneView.scene.rootNode.addChildNode(bottomPlaneNode)
        */
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
                print(hit.node.name!)
                let results = hitTest.first!
                let geometry = results.node.geometry
                print(geometry!.name!)
            }
        }
    }
    
    @objc func handleSandwichToss(sender: UIPanGestureRecognizer)
    {
        if(sender.state == UIGestureRecognizerState.began)
        {
            let tapPoint=sender.location(in: sceneView)
            guard let hit=sceneView.hitTest(tapPoint, options: nil).first else { return }
            let node = hit.node
        
            if (node.name?.range(of:"sand") != nil)
            {
                
                //let _typ = String(describing: type(of: node))

                print("Just touched \(node.name!)")
                print("Parent \(node.parent!.name!)")
                
                
                /*
                let velocity = sender.velocity(in: sceneView)
                let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
            
                let impulseFactor = Float(magnitude / 100)
                guard let pointOfView = self.sceneView.pointOfView else {return}
                let transform = pointOfView.transform
                let location = SCNVector3(transform.m41, transform.m42, transform.m43)
                let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
                let position = location + orientation
                node.position = position
                node.physicsBody?.applyForce(SCNVector3(orientation.x*impulseFactor,
                                                            orientation.y*impulseFactor,
                                                            orientation.z*impulseFactor),
                                                    asImpulse: true)
                */
            }
        }
    }
    

    

    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    {
        // to detect planes
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Create a SceneKit plane to visualize the node using its position and extent.
    
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = VirtualObject(name:"Floor")
        planeNode.createPlaneWith(geo: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        node.addChildNode(planeNode)
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor)
    {
        guard anchor is ARPlaneAnchor else { return }
        // remove existing plane nodes
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
    {
        let lightEstimate = self.sceneView.session.currentFrame?.lightEstimate
        
        // If light estimation is enabled, update the intensity of the model's lights
        if lightEstimate != nil &&  sessionConfiguration.isLightEstimationEnabled {
            let intensity = (lightEstimate?.ambientIntensity)! / 40
            self.sceneView.scene.lightingEnvironment.intensity = intensity
        } else {
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3
{
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
