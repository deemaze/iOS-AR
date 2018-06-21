//
//  RouteSegment.swift
//  ARPOI
//
//  Created by António Lima on 21/06/2018.
//  Copyright © 2018 Deemaze. All rights reserved.
//

import CoreLocation

struct RouteSegment {
    var startLatitude: CLLocationDegrees
    var startLongitude: CLLocationDegrees
    var startAltitude: CLLocationDegrees
    
    var endLatitude: CLLocationDegrees
    var endLongitude: CLLocationDegrees
    var endAltitude: CLLocationDegrees
    
}
