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
    var routeSegments: [RouteSegment]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupARScene()
        
        setupPOIs()
        
        setupRouteSegments()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Run the view's session
        sceneLocationView.run()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        // TODO: remove
        if false {
            // get POIs
            if (pois.count == 0){
                pois = getPOIs()
            }
            
            // add POIs to AR Scene
            for poi in pois {
                addPOIToARScene(poi)
            }
        }
        else {
            // get route segments
            if (routeSegments.count == 0){
                routeSegments = getRouteSegments()
            }
            
            // add POIs to AR Scene
            for routeSegment in routeSegments {
                addRouteSegmentToARScene(routeSegment)
            }
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
    
    func setupRouteSegments() {
        routeSegments = []
    }
    
    func getPOIs() -> [PointOfInterest] {
        
        return [
            PointOfInterest(latitude: -52.504571, longitude: 0.019717, altitude: 0),
            PointOfInterest(latitude: -51.504571, longitude: 0.019717, altitude: 0),
            PointOfInterest(latitude: -50.504571, longitude: 0.019717, altitude: 0),
            PointOfInterest(latitude: 52.504571, longitude: -0.019717, altitude: 0),
            PointOfInterest(latitude: 51.504571, longitude: -0.019717, altitude: 0),
            PointOfInterest(latitude: 50.504571, longitude: -0.019717, altitude: 0)
        ]
    }
    
    func getRouteSegments() -> [RouteSegment] {
        
        return [
            RouteSegment(startLatitude: 40.211338, startLongitude: -8.421190, startAltitude: 0,
                         endLatitude: 40.212291, endLongitude: -8.423103, endAltitude: 0),
            RouteSegment(startLatitude: 40.212291, startLongitude: -8.423103, startAltitude: 0,
                         endLatitude: 40.212370, endLongitude: -8.423849, endAltitude: 0),
            RouteSegment(startLatitude: 40.212370, startLongitude: -8.423849, startAltitude: 0,
                         endLatitude: 40.210334, endLongitude: -8.420870, endAltitude: 0),
            RouteSegment(startLatitude: 40.210334, startLongitude: -8.420870, startAltitude: 0,
                         endLatitude: 40.211142, endLongitude: -8.422336, endAltitude: 0),
            RouteSegment(startLatitude: 40.211142, startLongitude: -8.422336, startAltitude: 0,
                         endLatitude: 40.210830, endLongitude: -8.422673, endAltitude: 0)
        ]
    }
    
    func addPOIToARScene(_ poi: PointOfInterest) {
        let location = CLLocation(latitude: poi.latitude, longitude: poi.longitude)
        let annotationNode = LocationAnnotationNode(location: location, image: UIImage(named: "LocationMarker")!)
        
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
    }
    
    func addRouteSegmentToARScene(_ routeSegment: RouteSegment) {
        
        let startLocation = CLLocation(latitude: routeSegment.startLatitude, longitude: routeSegment.startLongitude)
        let endLocation = CLLocation(latitude: routeSegment.endLatitude, longitude: routeSegment.endLongitude)

        let startNode = RouteAnnotationNode(location: startLocation)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: startNode)
        
        let endNode = RouteAnnotationNode(location: endLocation)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: endNode)

        let routeSegmentAnnotationNode = RouteSegmentAnnotationNode(startNode: startNode, endNode: endNode)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: routeSegmentAnnotationNode)

    }
    
    func addDestinationPOIToARScene(_ poi: PointOfInterest) {
        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude), altitude: poi.altitude)
        let routeAnnotationNode = RouteAnnotationNode(location: location, color: .red)
        
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: routeAnnotationNode)
    }
    
    // MARK: AR Scene
    
    func setupARScene() {
        sceneLocationView = SceneLocationView()
        
        view.addSubview(sceneLocationView)

    }
    
}
