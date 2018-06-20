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

class ARCLViewController: UIViewController {
    
    var sceneLocationView: SceneLocationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        setupARScene()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Run the view's session
        sceneLocationView.run()
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
    
    // MARK: AR Scene
    
    func setupARScene() {
        sceneLocationView = SceneLocationView()
        
        view.addSubview(sceneLocationView)

    }
    
}
