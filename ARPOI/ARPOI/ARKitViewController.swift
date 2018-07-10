//
//  ARKitViewController.swift
//  ARPOI
//
//  Created by António Lima on 19/06/2018.
//  Copyright © 2018 Deemaze. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation

@available(iOS 11.0, *)
class ARKitViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager!
    var latestLocation: CLLocation?
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocation()
        
        setupARScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: location
    
    func setupLocation() {
        // Setup location manager
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // don't need more for POIs
        
        locationManager?.startUpdatingLocation()
        locationManager?.requestWhenInUseAuthorization()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager didFailWithError: %@", error)
        let alertController = UIAlertController(title: "LocationManager Error", message: "Failed to Get Your Location", preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("LocationManager didUpdateLocations: %@", locations)
        
        if (locations.count > 0) {
            latestLocation = locations.last!
            // latestLocation.coordinate.longitude
            // latestLocation.coordinate.latitude
        }
    }
    
    // MARK: AR Scene
    
    func setupARScene() {
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // debug options
        sceneView.debugOptions = [
            ARSCNDebugOptions.showFeaturePoints,
            ARSCNDebugOptions.showWorldOrigin
        ]
        
        // Create a new scene and set it to the view
        sceneView.scene = SCNScene()
        
        // Create a blue spherical node with a 0.2m radius
        let circleNode = createSphereNode(with: 0.2, color: .blue)
        
        // Position it 1 meter in front of camera
        circleNode.position = SCNVector3(0, 0, -1)
        
        // Add the node to the AR scene
        sceneView.scene.rootNode.addChildNode(circleNode)
    }
    
    func createSphereNode(with radius: CGFloat, color: UIColor) -> SCNNode {
        let geometry = SCNSphere(radius: radius)
        geometry.firstMaterial?.diffuse.contents = color
        let sphereNode = SCNNode(geometry: geometry)
        return sphereNode
    }

    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("ARSession didFailWithError: %@", error)
        let alertController = UIAlertController(title: "ARSession Error", message: error.localizedDescription, preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        print("ARSession sessionWasInterrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        print("ARSession sessionInterruptionEnded")
    }
}
