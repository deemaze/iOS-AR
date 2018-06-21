//
//  RouteSegmentNode.swift
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

///A location node can be added to a scene using a coordinate.
///Its scale and position should not be adjusted, as these are used for scene layout purposes
///To adjust the scale and position of items within a node, you can add them to a child node and adjust them there
open class RouteSegmentNode: SCNNode {
    /// Location can be changed and confirmed later by SceneLocationView.
    public var location: CLLocation!
    
    /// A general purpose tag that can be used to find nodes already added to a SceneLocationView
    public var tag: String?
    
    ///Whether the location of the node has been confirmed.
    ///This is automatically set to true when you create a node using a location.
    ///Otherwise, this is false, and becomes true once the user moves 100m away from the node,
    ///except when the locationEstimateMethod is set to use Core Location data only,
    ///as then it becomes true immediately.
    public var locationConfirmed = false
    
    ///Whether a node's position should be adjusted on an ongoing basis
    ///based on its' given location.
    ///This only occurs when a node's location is within 100m of the user.
    ///Adjustment doesn't apply to nodes without a confirmed location.
    ///When this is set to false, the result is a smoother appearance.
    ///When this is set to true, this means a node may appear to jump around
    ///as the user's location estimates update,
    ///but the position is generally more accurate.
    ///Defaults to true.
    public var continuallyAdjustNodePositionWhenWithinRange = true
    
    ///Whether a node's position and scale should be updated automatically on a continual basis.
    ///This should only be set to false if you plan to manually update position and scale
    ///at regular intervals. You can do this with `SceneLocationView`'s `updatePositionOfLocationNode`.
    public var continuallyUpdatePositionAndScale = true
    
    public init(location: CLLocation?) {
        self.location = location
        self.locationConfirmed = location != nil
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class RouteSegmentAnnotationNode: RouteSegmentNode {
    
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
