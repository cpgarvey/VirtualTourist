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
    var pin: Pin?

    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let photo = photo {
            imageView.image = photo.photoImage
        }
        
        /* Set up the delete button */
        let deleteButton = UIBarButtonItem(title: "Delete Photo", style: .Plain, target: self, action: #selector(PhotoDetailViewController.deletePhotoFromButton))
        deleteButton.tintColor = UIColor.redColor()
        self.navigationItem.rightBarButtonItem = deleteButton
        
    }
    
    
    // MARK: Delete Function
    
    func deletePhotoFromButton() {
        pin?.deleteSelectedPhotos([photo!])
        navigationController?.popViewControllerAnimated(true)
    }
    
    
    // MARK: - 3D Touch Action Menu
    
    override func previewActionItems() -> [UIPreviewActionItem] {
        
        let deleteAction = UIPreviewAction(title: "Delete", style: .Destructive) { (action, viewController) -> Void in
            
            /* If the user presses delete, have the pin delete the photo */
            self.pin?.deleteSelectedPhotos([self.photo!])
        }
        
        return [deleteAction]
    }
    
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
}
