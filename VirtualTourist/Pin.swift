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
    @NSManaged var mapSnapshot: NSData
    @NSManaged var photos: [Photo]
    @NSManaged var pageNumber: Int
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(annotationLatitude: Double, annotationLongitude: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = NSNumber(double: annotationLatitude)
        longitude = NSNumber(double: annotationLongitude)
        takeSnapshot()
        pageNumber = 1
        
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    @objc var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude as Double, longitude: longitude as Double)
    }
    
    func takeSnapshot() {
        
        // citation: http://nshipster.com/mktileoverlay-mkmapsnapshotter-mkdirections/
        // Apple reference: https://developer.apple.com/library/ios/documentation/MapKit/Reference/MKMapSnapshotter_class/index.html#//apple_ref/swift/cl/c:objc(cs)MKMapSnapshotter
        let options = MKMapSnapshotOptions()
        let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        options.region = MKCoordinateRegion(center: coordinate, span: span)
        options.size = CGSize(width: CGFloat(600), height: CGFloat(136))
        options.scale = UIScreen.mainScreen().scale
        
        let snapshotter = MKMapSnapshotter(options: options)
        
        snapshotter.startWithQueue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { snapshot, error in
            guard let snapshot = snapshot else {
                print("Snapshot error: \(error)")
                fatalError()
            }
            
            let pin = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
            let image = snapshot.image
            
            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
            image.drawAtPoint(CGPoint.zero)
            
            let visibleRect = CGRect(origin: CGPoint.zero, size: image.size)
            var point = snapshot.pointForCoordinate(self.coordinate)
            if visibleRect.contains(point) {
                point.x = point.x + pin.centerOffset.x - (pin.bounds.size.width / 2)
                point.y = point.y + pin.centerOffset.y - (pin.bounds.size.height / 2)
                pin.image?.drawAtPoint(point)
            }
            
            let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            self.mapSnapshot = UIImagePNGRepresentation(compositeImage)!
            
        }
            
    }
    
}
