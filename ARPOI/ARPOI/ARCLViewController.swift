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
    var locationAnnotationNode2POI: [LocationTextAnnotationNode: PointOfInterest]!
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
        resetARScene()
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
                let tappedNode = hits.first?.node.parent as! LocationTextAnnotationNode
                if let poi = locationAnnotationNode2POI?[tappedNode] {
                    presentPOIAlertViewfor(poi: poi)
                }
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
        self.presentConfirmationAlertViewWith(
            title: "Location Error",
            message: "Failed to get your current location.",
            handler: nil
        )
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
        locationAnnotationNode2POI = [LocationTextAnnotationNode: PointOfInterest]()
        drawnLocationNodes = []
    }
    
    func getPOIs() {
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)
        request.region = MKCoordinateRegion(center: (latestLocation?.coordinate)!,
                                            latitudinalMeters: 2000,
                                            longitudinalMeters: 2000)
        
        let search = MKLocalSearch(request: request)
        print("Getting POIs")
        search.start {
            (response, error) in
            
            guard let response = response else {
                if let error = error {
                    // show alert with error and ok button for reset
                    print("Search error: \(error)")

                    self.presentConfirmationAlertViewWith(
                        title: "POIs Error",
                        message: "Could not fetch POIS near your current location.",
                        handler: { action in
                            self.resetARScene()
                    })
                }
                return
            }

            print("Got POIs")

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
        print("Getting directions")
        directions.calculate {
            (response, error) -> Void in
            
            guard let response = response else {
                if let error = error {
                    // Show alert with error and ok button for reset
                    print("Error: \(error)")

                    let poiString = self.selectedPOI?.title ?? "the POI"
                    self.presentConfirmationAlertViewWith(
                        title: "Directions Error",
                        message: "Could not fetch directions between your current location and \(poiString).",
                        handler: { action in
                            self.resetARScene()
                    })
                }
                return
            }

            print("Got directions")

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

            // add route coordinates together so we can build our AR path
            var routeCoordinates = [CLLocationCoordinate2D]()
            for step in route.steps {
                
                let pointCount = step.polyline.pointCount
                let stepCoordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: pointCount)
                step.polyline.getCoordinates(stepCoordinates, range: NSRange(location: 0, length: pointCount))

                for i in 0..<pointCount {
                    routeCoordinates.append(stepCoordinates[i])
                }
            }

            for i in 0..<routeCoordinates.count-1 {

                let startCoordinate = routeCoordinates[i]
                let endCoordinate = routeCoordinates[i+1]

                let routeSegment = RouteSegment(startLatitude: startCoordinate.latitude, startLongitude: startCoordinate.longitude, startAltitude: 0,
                                                endLatitude: endCoordinate.latitude, endLongitude: endCoordinate.longitude, endAltitude: 0)
                self.addRouteSegmentToARScene(routeSegment)
            }
            
            // handle destination
            
            let finalStepCoordinate = routeCoordinates[routeCoordinates.count-1]
            let routeSegment = RouteSegment(startLatitude: finalStepCoordinate.latitude, startLongitude: finalStepCoordinate.longitude, startAltitude: 0,
                                            endLatitude: selectedPOI!.latitude, endLongitude: selectedPOI!.longitude, endAltitude: 0)
            self.addFinalRouteSegmentToARScene(routeSegment)
        }
    }
    
    // MARK: AR Scene
    
    func addPOIToARScene(_ poi: PointOfInterest) {
        let location = CLLocation(latitude: poi.latitude, longitude: poi.longitude)
        let text = poi.title.replacingOccurrences(of: ", ", with: "\n")
        let annotationNode = LocationTextAnnotationNode(location: location, image: UIImage(named: "LocationMarker")!, text: text)
        
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        drawnLocationNodes.append(annotationNode)
        locationAnnotationNode2POI[annotationNode] = poi
    }

    func addFinalRouteSegmentToARScene(_ routeSegment: RouteSegment) {
        
        let startLocation = CLLocation(latitude: routeSegment.startLatitude, longitude: routeSegment.startLongitude)
        let startNode = RouteAnnotationNode(location: startLocation)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: startNode)
        drawnLocationNodes.append(startNode)
        
        self.addDestinationPOIToARScene(selectedPOI!)
        let endNode = drawnLocationNodes.last as! RouteAnnotationNode
        
        let routeSegmentAnnotationNode = RouteSegmentAnnotationNode(startNode: startNode, endNode: endNode)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: routeSegmentAnnotationNode)
        drawnLocationNodes.append(routeSegmentAnnotationNode)
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
            getPOIs()
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

    // MARK: Alert views

    func presentConfirmationAlertViewWith(title: String, message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: handler))
        self.present(alert, animated: true, completion: nil)
    }

    func presentPOIAlertViewfor(poi: PointOfInterest) {
        let alert = UIAlertController(title: poi.title,
                                      message: "",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Get directions", style: .default, handler: { action in
            self.selectedPOI = poi
            self.clearNodesAndRedrawARScene()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

}
