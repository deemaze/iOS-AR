//
//  ARCLViewController.swift
//  ARPOI
//
//  Created by António Lima on 20/06/2018.
//  Copyright © 2018 Deemaze. All rights reserved.
//

import UIKit
import ARCL
import CoreLocation

@available(iOS 11.0, *)
class ARCLViewController: UIViewController {
    
    var sceneLocationView: SceneLocationView!
    var pois: [PointOfInterest]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupARScene()
        
        setupPOIs()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Run the view's session
        sceneLocationView.run()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        // get POIs
        if (pois.count == 0){
            pois = getPOIs()
        }
        
        // add POIs to AR Scene
        for poi in pois {
            addPOIToARScene(poi)
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneLocationView.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sceneLocationView.frame = view.bounds
    }
    
    // MARK: POIs
    
    func setupPOIs() {
        pois = []
    }
    
    func getPOIs() -> [PointOfInterest] {
        
        return [
            PointOfInterest(latitude: 52.504571, longitude: 0.019717),
            PointOfInterest(latitude: 51.504571, longitude: 0.019717),
            PointOfInterest(latitude: 50.504571, longitude: 0.019717),
            PointOfInterest(latitude: 52.504571, longitude: -0.019717),
            PointOfInterest(latitude: 51.504571, longitude: -0.019717),
            PointOfInterest(latitude: 50.504571, longitude: -0.019717)
        ]
    }
    
    func addPOIToARScene(_ poi: PointOfInterest) {
        
    }
    
    // MARK: AR Scene
    
    func setupARScene() {
        sceneLocationView = SceneLocationView()
        
        view.addSubview(sceneLocationView)

    }
    
}
