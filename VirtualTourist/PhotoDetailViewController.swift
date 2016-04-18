//
//  PhotoDetailViewController.swift
//  VirtualTourist
//
//  Created by Chris Garvey on 4/17/16.
//  Copyright © 2016 Chris Garvey. All rights reserved.
//

import UIKit
import CoreData


class PhotoDetailViewController: UIViewController {

    
    // MARK: - Properties
    
    @IBOutlet weak var imageView: UIImageView!
    
    var photo: Photo?

    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let photo = photo {
            imageView.image = photo.photoImage
        }
    }
    
    
    // MARK: - 3D Touch Action Menu
    
    override func previewActionItems() -> [UIPreviewActionItem] {
        
        let deleteAction = UIPreviewAction(title: "Delete", style: .Destructive) { (action, viewController) -> Void in
            
            /* If the user presses delete, delete the photo */
            FlickrClient.Caches.imageCache.deleteImage(self.photo!.photoID)
            self.sharedContext.deleteObject(self.photo!)
            
            CoreDataStackManager.sharedInstance().saveContext()
            
        }
        
        return [deleteAction]
    }
    
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
}
