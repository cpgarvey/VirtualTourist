//
//  Pin.swift
//  VirtualTourist
//
//  Created by Chris Garvey on 4/4/16.
//  Copyright © 2016 Chris Garvey. All rights reserved.
//

import Foundation
import MapKit

class Pin: NSObject, MKAnnotation {
    
    var latitude: NSNumber
    var longitude: NSNumber
    
    init(annotationLatitude: Double, annotationLongitude: Double) {
        
        latitude = NSNumber(double: annotationLatitude)
        longitude = NSNumber(double: annotationLongitude)
    }
    
    @objc var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude as Double, longitude: longitude as Double)
    }
    
}
