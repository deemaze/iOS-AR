//
//  RouteAnnotationNode.swift
//  ARPOI
//
//  Created by António Lima on 22/06/2018.
//  Copyright © 2018 Deemaze. All rights reserved.
//
//  Inspired by: LocationNode.swift by Andrew Hart
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import SceneKit
import CoreLocation
import ARCL

open class RouteAnnotationNode: LocationNode {
    
    public let annotationNode: SCNNode
    
    ///Whether the node should be scaled relative to its distance from the camera
    ///Setting to true causes annotation nodes to scale like a regular node
    ///Scaling relative to distance may be useful with local navigation-based uses
    ///For landmarks in the distance, the default is correct
    ///Setting it to false scales the node to visually appear at the same size no matter the distance
    public var scaleRelativeToDistance = true
    
    public init(location: CLLocation, color: UIColor? = .blue) {
        
        
        let sphere = SCNSphere(radius: 5)
        sphere.firstMaterial!.diffuse.contents = color
        sphere.firstMaterial!.lightingModel = .phong
        sphere.firstMaterial!.fillMode = .lines
        
        annotationNode = SCNNode()
        annotationNode.geometry = sphere
        
        super.init(location: location)
        
        addChildNode(annotationNode)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
