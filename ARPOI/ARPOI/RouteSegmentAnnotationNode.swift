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
    
    public let routeNode: SCNNode
    public let textNode: SCNNode
    
    ///Whether the node should be scaled relative to its distance from the camera
    ///Setting to true causes annotation nodes to scale like a regular node
    ///Scaling relative to distance may be useful with local navigation-based uses
    ///For landmarks in the distance, the default is correct
    ///Setting it to false scales the node to visually appear at the same size no matter the distance
    public var scaleRelativeToDistance = true
    
    public init(startNode: RouteAnnotationNode, endNode: RouteAnnotationNode) {
        
        // the node is set between the start and end locations
        let startLocation = startNode.location!
        let endLocation = endNode.location!
        let coordinateInBetween = CLLocationCoordinate2D(latitude: (startLocation.coordinate.latitude + endLocation.coordinate.latitude)/2.0,
                                   longitude: (startLocation.coordinate.longitude + endLocation.coordinate.longitude)/2.0)
        let locationInBetween = CLLocation(coordinate: coordinateInBetween,
                                           altitude: (startLocation.altitude + endLocation.altitude)/2.0)
        
        routeNode = LineNode(start: startNode.position, end: endNode.position)
        textNode = TextNode(startLocation: startLocation, endLocation: endLocation)
        
        super.init(location: locationInBetween)
        
        addChildNode(routeNode)
        addChildNode(textNode)
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class TextNode: SCNNode {
    
    init(startLocation: CLLocation, endLocation: CLLocation) {
        super.init()
        
        let distance = Int( round( startLocation.distance(from: endLocation)))
        
        let textShape = SCNText(string: "\(distance) m", extrusionDepth: 1)
        textShape.firstMaterial!.diffuse.contents = UIColor.white
        textShape.firstMaterial!.specular.contents = UIColor.black
        textShape.firstMaterial!.lightingModel = .phong
        textShape.isWrapped = true
        textShape.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        
        let textNode = SCNNode()
        textNode.geometry = textShape
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        constraints = [billboardConstraint]
        
        addChildNode(textNode)
        
        // center text correctly around the origin (x axis only) (SCNText's origins in in the bottom left corner)
        let min = textNode.boundingBox.min
        let max = textNode.boundingBox.max
        textNode.pivot = SCNMatrix4MakeTranslation((max.x - min.x) / 2, 0, 0);
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class LineNode: SCNNode{
    
    init(start: SCNVector3, end: SCNVector3) {
        super.init()
        
        let distance = distanceBetweenScenePoints(pointA: start, pointB: end)
        
        position = start
        
        let endNode = SCNNode()
        
        endNode.position = end
        
        let ndZAlign = SCNNode()
        ndZAlign.eulerAngles.x = Float.pi/2
        
        let cylgeo = SCNBox(width: 5, height: distance, length: 5, chamferRadius: 0)
        cylgeo.firstMaterial!.diffuse.contents = UIColor.cyan
        cylgeo.firstMaterial!.lightingModel = .phong
        // cylgeo.firstMaterial!.fillMode = .lines // used for debug purposes
        
        let ndCylinder = SCNNode(geometry: cylgeo)
        ndCylinder.position.y = Float(-distance/2) + 0.001
        ndZAlign.addChildNode(ndCylinder)
        
        addChildNode(ndZAlign)
        
        constraints = [SCNLookAtConstraint(target: endNode)]
    }
    
    
    func distanceBetweenScenePoints(pointA: SCNVector3, pointB: SCNVector3) -> CGFloat {
        let distance = sqrt(
            (pointA.x - pointB.x) * (pointA.x - pointB.x) +
            (pointA.y - pointB.y) * (pointA.y - pointB.y) +
            (pointA.z - pointB.z) * (pointA.z - pointB.z)
        )
        return CGFloat(distance)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
