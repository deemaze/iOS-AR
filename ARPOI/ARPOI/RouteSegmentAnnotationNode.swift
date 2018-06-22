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
        
//        let routeGeometry = SCNGeometry().lineFrom(vector: startNode.position, toVector: endNode.position)
//        routeGeometry.firstMaterial!.diffuse.contents = UIColor.cyan
//        routeGeometry.firstMaterial!.lightingModel = .phong
//        routeNode = SCNNode()
//        routeNode.geometry = routeGeometry
        
        super.init(location: locationInBetween)
        
        addChildNode(routeNode)
        
//        // ------
//        // for debug purposes
//        let routeGeometryCopy = SCNCylinder(radius: 5, height: distance)
//        routeGeometryCopy.firstMaterial!.diffuse.contents = UIColor.red
//        routeGeometryCopy.firstMaterial!.lightingModel = .phong
//        routeGeometryCopy.firstMaterial!.fillMode = .lines
//        let routeNodeCopy = SCNNode()
//        routeNodeCopy.geometry = routeGeometryCopy
//        addChildNode(routeNodeCopy)
//        // ------
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

//extension SCNGeometry {
//    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
//
//        let indices: [Int32] = [0, 1]
//        let source = SCNGeometrySource(vertices: [vector1, vector2])
//        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
//
//        return SCNGeometry(sources: [source], elements: [element])
//    }
//}

class LineNode: SCNNode{
    
    init(start: SCNVector3, end: SCNVector3) {
        super.init()
        
        let distance = distanceBetweenPoints2(pointA: start, pointB: end)
        
        position = start
        
        let endNode = SCNNode()
        
        endNode.position = end
        
        let ndZAlign = SCNNode()
        ndZAlign.eulerAngles.x = Float.pi/2
        
        let cylgeo = SCNBox(width: 5, height: distance, length: 5, chamferRadius: 0)
        cylgeo.firstMaterial!.diffuse.contents = UIColor.cyan
        cylgeo.firstMaterial!.lightingModel = .phong
        cylgeo.firstMaterial!.fillMode = .lines
        
        let ndCylinder = SCNNode(geometry: cylgeo )
        ndCylinder.position.y = Float(-distance/2) + 0.001
        ndZAlign.addChildNode(ndCylinder)
        
        addChildNode(ndZAlign)
        
        constraints = [SCNLookAtConstraint(target: endNode)]
    }
    
    
    func distanceBetweenPoints2(pointA: SCNVector3, pointB: SCNVector3) -> CGFloat {
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
