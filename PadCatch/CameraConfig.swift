

import Foundation
import ARKit

class CameraConfig
{
    

    var cameraNode = SCNNode()
    var scnCam = SCNCamera()
    
    struct CameraCoordinates
    {
        var x = Float()
        var y = Float()
        var z = Float()
    }
    
    func initCam(sceneView:ARSCNView)
    {
        cameraNode.name = "PadCam"
        cameraNode.camera=scnCam
        sceneView.scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3Make(0, 0, 0)
        print("cameraNode position - \(cameraNode.position)")
        print("cameraNode orientation - \(cameraNode.orientation)")
        

    }
    
    func configureDisplay(sceneView: ARSCNView)
    {
        
            scnCam.wantsHDR = true
            scnCam.wantsExposureAdaptation = true
            scnCam.exposureOffset = -1
            scnCam.minimumExposure = -1
        
        
    }
    
    // to position the object in the camera's coordinate
    func getCameraCoordinates(sceneView: ARSCNView) -> CameraCoordinates
    {
            var coordinates = CameraCoordinates()
            coordinates.x = cameraNode.position.x
            coordinates.y = cameraNode.position.y
            coordinates.z = cameraNode.position.z
            return coordinates
    }
    
    
}

