//
//  Photo.swift
//  VirtualTourist
//
//  Created by Chris Garvey on 4/11/16.
//  Copyright © 2016 Chris Garvey. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class Photo: NSManagedObject {
    
    @NSManaged var photoPath: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(photoPath: String, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.photoPath = photoPath
    }
    
    var photoImage: UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(photoPath)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: photoPath)
        }
    }
    
}
