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
    
    @IBOutlet weak var resetButton: UIBarButtonItem!
    
    var locationManager: CLLocationManager!
    var latestLocation: CLLocation?
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var sceneLocationView: SceneLocationView!
    
    var pois: [PointOfInterest]!
    var locationAnnotationNode2POI: [LocationAnnotationNode: PointOfInterest]!
    var selectedPOI: PointOfInterest?
    
    var drawnLocationNodes: [LocationNode]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toggleResetButtonStatus()
        
        setupLocation()
        
        setupPOIs()
        
        setupARScene()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Run the view's session
        sceneLocationView.run()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        drawARScene()
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
    
    // MARK: Navigation bar actions
    
    func toggleSegmentControl() {
        if selectedPOI == nil {
            showSegmentControl()
        }
        else {
            hideSegmentControl()
        }
    }
    
    func hideSegmentControl() {
        // hide
        resetButton.tintColor = .clear
        resetButton.isEnabled = false
        resetButton.isAccessibilityElement = false
    }
    
    func showSegmentControl() {
        // show
        resetButton.tintColor = .blue
        resetButton.isEnabled = true
        resetButton.isAccessibilityElement = true
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        // re-draw the AR scene
        clearNodesAndRedrawARScene()
    }
    
    func toggleResetButtonStatus() {
        if selectedPOI == nil {
            hideResetButton()
        }
        else {
            showResetButton()
        }
    }
    
    func hideResetButton() {
        // hide
        resetButton.tintColor = .clear
        resetButton.isEnabled = false
        resetButton.isAccessibilityElement = false
    }
    
    func showResetButton() {
        // show
        resetButton.tintColor = .blue
        resetButton.isEnabled = true
        resetButton.isAccessibilityElement = true
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        resetARScene()
    }
    
    // MARK: AR scene actions
    
    @objc
    func handleARObjectTap(gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.view != nil else { return }
        
        if gestureRecognizer.state == .ended {
            
            // Look for an object directly under the touch location
            let location: CGPoint = gestureRecognizer.location(in: sceneLocationView)
            let hits = sceneLocationView.hitTest(location, options: nil)
            if !hits.isEmpty {
                
                // select the first match
                let tappedNode = hits.first?.node.parent as! LocationAnnotationNode
                selectedPOI = locationAnnotationNode2POI?[tappedNode]

                clearNodesAndRedrawARScene()
            }
            
        }
    }
    
    
    // MARK: location
    
    func setupLocation() {
        // Setup location manager
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // don't need more for walking between POIs
        
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
        locationAnnotationNode2POI = [LocationAnnotationNode: PointOfInterest]()
        drawnLocationNodes = []
    }
    
    func getPOIs() {
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)
        request.region = MKCoordinateRegion(center: (latestLocation?.coordinate)!,
                                            latitudinalMeters: 2000,
                                            longitudinalMeters: 2000)
        
        let search = MKLocalSearch(request: request)
        search.start {
            (response, error) in
            
            guard let response = response else {
                if let error = error {
                    print("Search error: \(error)")
                }
                return
            }
            
            self.pois = []
            
            for item in response.mapItems {
                let coordinate = item.placemark.coordinate
                let poi = PointOfInterest(title: item.placemark.title!,
                                          latitude: coordinate.latitude,
                                          longitude: coordinate.longitude,
                                          altitude: 0)
                self.pois.append( poi)
                self.addPOIToARScene(poi)
            }
        }
    }
    
    // MARK: Directions
    
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
    
    // MARK: AR Scene
    
    func addPOIToARScene(_ poi: PointOfInterest) {
        let location = CLLocation(latitude: poi.latitude, longitude: poi.longitude)
        let annotationNode = LocationAnnotationNode(location: location, image: UIImage(named: "LocationMarker")!)
        
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        drawnLocationNodes.append(annotationNode)
        locationAnnotationNode2POI[annotationNode] = poi
    }
    
    func addRouteSegmentToARScene(_ routeSegment: RouteSegment) {
        
        let startLocation = CLLocation(latitude: routeSegment.startLatitude, longitude: routeSegment.startLongitude)
        let startNode = RouteAnnotationNode(location: startLocation)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: startNode)
        drawnLocationNodes.append(startNode)
        
        let endLocation = CLLocation(latitude: routeSegment.endLatitude, longitude: routeSegment.endLongitude)
        let endNode = RouteAnnotationNode(location: endLocation)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: endNode)
        drawnLocationNodes.append(endNode)
        
        let routeSegmentAnnotationNode = RouteSegmentAnnotationNode(startNode: startNode, endNode: endNode)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: routeSegmentAnnotationNode)
        drawnLocationNodes.append(routeSegmentAnnotationNode)
    }
    
    func addDestinationPOIToARScene(_ poi: PointOfInterest) {
        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude), altitude: poi.altitude)
        let routeAnnotationNode = RouteAnnotationNode(location: location, color: .red)
        
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: routeAnnotationNode)
        drawnLocationNodes.append(routeAnnotationNode)
    }
    
    func setupARScene() {
        sceneLocationView = SceneLocationView()
        view.addSubview(sceneLocationView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleARObjectTap(gestureRecognizer:)))
        sceneLocationView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func drawARScene() {
        
        if selectedPOI == nil {
            // get POIs
            if (pois.count == 0){
                getPOIs()
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
    
    func clearNodesAndRedrawARScene() {

        for locationNode in drawnLocationNodes {
            sceneLocationView.removeLocationNode(locationNode: locationNode)
        }
        
        drawnLocationNodes = []
        
        toggleResetButtonStatus()
        toggleSegmentControl()
        
        drawARScene()
    }
    
    func resetARScene() {
        selectedPOI = nil
        clearNodesAndRedrawARScene()
    }
    
}
