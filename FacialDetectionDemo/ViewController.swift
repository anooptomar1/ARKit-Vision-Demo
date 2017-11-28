//
//  ViewController.swift
//  FacialDetectionDemo
//
//  Created by Brandon Andrews on 11/25/17.
//

import UIKit
import ARKit
import Vision

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup and configure AR
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        self.sceneView.session.delegate = self
        
        // Debug options
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.showsStatistics = true
        
        sceneView.autoenablesDefaultLighting = true
        self.sceneView.session.run(configuration)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        sceneView.session.pause()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let faceRequest = VNDetectFaceRectanglesRequest { request, error in
            guard error == nil else {
                print("Face request error: \(error!.localizedDescription)")
                return
            }
            
            guard let observations = request.results as? [VNFaceObservation], observations.count > 0 else {
                return
            }
            
            for face in observations {
                // Get the position the face was detected at using a hit test
                let arHitTestResults = frame.hitTest(CGPoint(x: face.boundingBox.midX, y: face.boundingBox.midY), types: [.featurePoint])
                
                if let hitTestResult = arHitTestResults.first {
                    // Just placing a SCNSphere at the spot of the face for this demo.
                    // Replace this below with whatever you want to display.
                    let node = SCNNode()
                    node.geometry = SCNSphere(radius: 0.1)
                    node.transform = SCNMatrix4(hitTestResult.worldTransform)
                    
                    // Add the node to the sceneView as child node of the root node.
                    self.sceneView.scene.rootNode.addChildNode(node)
                }
            }
        }
        
        // Process the frame on a background thread
        DispatchQueue.global(qos: .userInitiated).async {            
            try? VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: self.deviceOrientation(), options: [:]).perform([faceRequest])
        }
    }
    
    /// Determine what orientation the device is currently in.
    /// This is essential to get accurate results from VNImageRequestHandler
    /// because it is looking for faces based on which direction the face
    /// is orientated.
    ///
    /// - Returns: .up = landscape
    ///            .right = portrait
    func deviceOrientation() -> CGImagePropertyOrientation {
        let orientation: CGImagePropertyOrientation
        
        if UIDevice.current.orientation.isLandscape {
            orientation = CGImagePropertyOrientation.up
        } else {
            orientation = CGImagePropertyOrientation.right
        }
        return orientation
    }
}
