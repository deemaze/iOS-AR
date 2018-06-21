//
//  RouteSegmentAnnotationNode.swift
//  ARPOI
//
//  Created by António Lima on 21/06/2018.
//  Copyright © 2018 Deemaze. All rights reserved.
//
//  Inspired by: LocationNode.swift by Andrew Hart
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import SceneKit
import CoreLocation
import ARCL

open class RouteSegmentAnnotationNode: LocationNode {
    
    ///Subnodes and adjustments should be applied to this subnode
    ///Required to allow scaling at the same time as having a 2D 'billboard' appearance
    public let annotationNode: SCNNode
    
    ///Whether the node should be scaled relative to its distance from the camera
    ///Setting to true causes annotation nodes to scale like a regular node
    ///Scaling relative to distance may be useful with local navigation-based uses
    ///For landmarks in the distance, the default is correct
    ///Setting it to false scales the node to visually appear at the same size no matter the distance
    public var scaleRelativeToDistance = true
    
    public init(startLocation: CLLocation, endLocation: CLLocation) {
        
        // the node is set between the start and end locations
        let distance = CGFloat(startLocation.distance(from: endLocation))
        let coordinateInBetween = CLLocationCoordinate2D(latitude: (startLocation.coordinate.latitude + endLocation.coordinate.latitude)/2.0,
                                   longitude: (startLocation.coordinate.longitude + endLocation.coordinate.longitude)/2.0)
        let locationInBetween = CLLocation(coordinate: coordinateInBetween,
                                           altitude: (startLocation.altitude + endLocation.altitude)/2.0)
        
        let routeCylinder = SCNCylinder(radius: 5, height: distance)
        routeCylinder.firstMaterial!.diffuse.contents = UIColor.cyan
        routeCylinder.firstMaterial!.lightingModel = .constant
        
        annotationNode = SCNNode()
        annotationNode.geometry = routeCylinder
        
        
        super.init(location: locationInBetween)
        
        addChildNode(annotationNode)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
