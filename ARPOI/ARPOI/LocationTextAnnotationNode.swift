//
//  LocationTextAnnotationNode.swift
//  ARPOI
//
//  Created by António Lima on 26/06/2018.
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
        
        let textShape = SCNText(string: text, extrusionDepth: 1)
        textShape.firstMaterial!.diffuse.contents = UIColor.white
        textShape.firstMaterial!.lightingModel = .phong
        textShape.isWrapped = true
        textShape.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        
        textAnnotationNode = SCNNode()
        textAnnotationNode.geometry = textShape
        
        super.init(location: location, image: image)
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        constraints = [billboardConstraint]
        
        addChildNode(textAnnotationNode)
        
        // center text correctly around (x) and below (y) origin (SCNText's origins in in the bottom left corner)
        let min = textAnnotationNode.boundingBox.min
        let max = textAnnotationNode.boundingBox.max
        textAnnotationNode.pivot = SCNMatrix4MakeTranslation((max.x - min.x) / 2, (max.y - min.y), 0);
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
