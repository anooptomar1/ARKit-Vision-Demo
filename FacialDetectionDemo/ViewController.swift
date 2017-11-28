//
//  ViewController.swift
//  FacialDetectionDemo
//
//  Created by Brandon Andrews on 11/25/17.
//

import UIKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var movePhoneLabel: UILabel!
    
    // Debug labels
    @IBOutlet weak var cameraStatus: UILabel!
    @IBOutlet weak var faceCountLabel: UILabel!
    
    // Debug properties
    // Controls see tracking status, feature points, and world origin
    let debug = true
    var faceCount = 0
    
    // Flag used to make sure we aren't processing unnecessary frames
    // from the ARSessionDelegate
    var processing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        sceneView.session.pause()
    }
    
    /// Setup the scene view.
    /// If we are currenly in debug mode we will show the various
    /// debug options.
    private func setupSceneView() {
        // Debug options
        if self.debug {
            self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
            self.sceneView.showsStatistics = true
        }
        
        self.sceneView.session.delegate = self
        self.sceneView.autoenablesDefaultLighting = true
        let configuration = ARWorldTrackingConfiguration()
        self.sceneView.session.run(configuration)
    }
    
    // ARSCNViewDelegate
    // Tracking state for camera
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        if self.debug {
            var cameraStatusMessage = "Tracking status: "
            
            switch camera.trackingState {
            case .normal:
                cameraStatusMessage += "Normal"
                cameraStatus.textColor = UIColor.green
                movePhoneLabel.isHidden = true
            case .limited(ARCamera.TrackingState.Reason.initializing):
                cameraStatusMessage += "Init"
                cameraStatus.textColor = UIColor.black
                movePhoneLabel.isHidden = false
            case .limited:
                cameraStatusMessage += "Limited"
                cameraStatus.textColor = UIColor.yellow
            case .notAvailable:
                cameraStatusMessage += "Not Available"
                cameraStatus.textColor = UIColor.red
            }
            cameraStatus.text = cameraStatusMessage
        }
    }
    
    // ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if self.processing {
            return
        }
        self.processing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: self.deviceOrientation(), options: [:]).perform([self.facesRequest(frame)])
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
    
    
    /// Use VNDetectFaceRectanglesRequest to detect faces in the
    /// frame. For all the faces found add a node at that point
    /// using a hit test.
    /// - Parameter frame: frame captured by the sceneView
    /// - Returns: the request ready to handover to a handler
    func facesRequest(_ frame: ARFrame) -> VNDetectFaceRectanglesRequest {
        return VNDetectFaceRectanglesRequest { request, error in
            guard error == nil else {
                print("Face request error: \(error!.localizedDescription)")
                self.processing = false
                return
            }
            
            guard let observations = request.results as? [VNFaceObservation], observations.count > 0 else {
                self.processing = false
                return
            }
           
            for face in observations {
                if self.debug {
                    self.faceCount += 1
                    DispatchQueue.main.async {
                        self.faceCountLabel.text = "Face count: \(self.faceCount)"
                    }
                }
                
                let arHitTestResults = frame.hitTest(CGPoint(x: face.boundingBox.midX, y: face.boundingBox.midY), types: [.featurePoint])
                
                if let hitTestResult = arHitTestResults.first {
                    let node = self.newSphereNode()
                    node.transform = SCNMatrix4(hitTestResult.worldTransform)
                    
                    self.sceneView.scene.rootNode.addChildNode(node)
                }
            }
            self.processing = false
        }
    }
    
    func newSphereNode() -> SCNNode {
        let node = SCNNode()
        node.geometry = SCNSphere(radius: 0.1)
        return node
    }
}


