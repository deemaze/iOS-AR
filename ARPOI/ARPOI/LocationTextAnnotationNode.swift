//
//  LocationTextAnnotationNode.swift
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

open class LocationTextAnnotationNode: LocationAnnotationNode {
    
    // text that is displayed by the SCNText
    public let text: String
    
    ///Subnodes and adjustments should be applied to this subnode
    ///Required to allow scaling at the same time as having a 2D 'billboard' appearance
    public let textAnnotationNode: SCNNode
    
    public init(location: CLLocation?, image: UIImage, text: String) {
        self.text = text
        
        let plane = SCNText(string: text, extrusionDepth: 0)
        plane.firstMaterial!.diffuse.contents = UIColor.white
        plane.firstMaterial!.lightingModel = .constant
        
        textAnnotationNode = SCNNode()
        textAnnotationNode.geometry = plane
        textAnnotationNode.localTranslate(by: SCNVector3Make(0, 0, -5))
        
        super.init(location: location, image: image)
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        constraints = [billboardConstraint]
        
        addChildNode(textAnnotationNode)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
