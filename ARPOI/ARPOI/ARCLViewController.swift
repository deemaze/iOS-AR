//
//  ARCLViewController.swift
//  ARPOI
//
//  Created by António Lima on 20/06/2018.
//  Copyright © 2018 Deemaze. All rights reserved.
//

import UIKit
import MapKit
import ARCL
import CoreLocation

@available(iOS 11.0, *)
class ARCLViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager!
    var latestLocation: CLLocation?
    
    var sceneLocationView: SceneLocationView!
    
    var pois: [PointOfInterest]!
    var selectedPOI: PointOfInterest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocation()
        
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
    
        if selectedPOI == nil {
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
            if latestLocation != nil {
                // get route segments
                getRouteSegments(startCoordinate: (latestLocation?.coordinate)!,
                                 endCoordinate: CLLocationCoordinate2D(latitude: (selectedPOI?.latitude)!,
                                                                       longitude: (selectedPOI?.longitude)!))
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
    
    // MARK: location
    
    func setupLocation() {
        // Setup location manager
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // don't need more for POIs
        
        locationManager?.startUpdatingLocation()
        locationManager?.requestWhenInUseAuthorization()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager didFailWithError: %@", error)
        let alertController = UIAlertController(title: "LocationManager Error", message: "Failed to Get Your Location", preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("LocationManager didUpdateLocations: %@", locations)
        
        if (locations.count > 0) {
            latestLocation = locations.last!
        }
    }
    
    // MARK: POIs
    
    func setupPOIs() {
        pois = []
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
    
    func getRouteSegments(startCoordinate: CLLocationCoordinate2D, endCoordinate: CLLocationCoordinate2D) {
        
        let directionRequest = setupRouteDirectionsRequest(startCoordinate: startCoordinate, endCoordinate: endCoordinate)
        
        // Request the directions between the two points
        let directions = MKDirections(request: directionRequest)
        directions.calculate {
            (response, error) -> Void in
            
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                return
            }
            
            // add route segments to AR Scene
            self.manageRouteDirections(response)
        }
    }
    
    func setupRouteDirectionsRequest(startCoordinate: CLLocationCoordinate2D, endCoordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let sourcePlacemark = MKPlacemark(coordinate: startCoordinate, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: endCoordinate, addressDictionary: nil)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let sourceAnnotation = MKPointAnnotation()
        
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }
        
        let destinationAnnotation = MKPointAnnotation()
        
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .walking
        
        return directionRequest
    }
    
    func manageRouteDirections(_ response: MKDirections.Response) {
        for route in response.routes {
            for step in route.steps {
                
                let pointCount = step.polyline.pointCount
                if pointCount == 2 {
                    
                    let routeCoordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: pointCount)
                    step.polyline.getCoordinates(routeCoordinates, range: NSMakeRange(0, pointCount))
                    
                    let startCoordinate = routeCoordinates[0]
                    let endCoordinate = routeCoordinates[1]
                    
                    let routeSegment = RouteSegment(startLatitude: startCoordinate.latitude, startLongitude: startCoordinate.longitude, startAltitude: 0,
                                                    endLatitude: endCoordinate.latitude, endLongitude: endCoordinate.longitude, endAltitude: 0)
                    self.addRouteSegmentToARScene(routeSegment)
                }
            }
        }
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
