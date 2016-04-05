//
//  Pin.swift
//  VirtualTourist
//
//  Created by Chris Garvey on 4/4/16.
//  Copyright © 2016 Chris Garvey. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class Pin: NSManagedObject, MKAnnotation {
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(annotationLatitude: Double, annotationLongitude: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = NSNumber(double: annotationLatitude)
        longitude = NSNumber(double: annotationLongitude)
    }
    
    @objc var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude as Double, longitude: longitude as Double)
    }
    
}
