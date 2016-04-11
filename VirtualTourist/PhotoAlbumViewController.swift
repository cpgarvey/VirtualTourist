//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Chris Garvey on 4/5/16.
//  Copyright © 2016 Chris Garvey. All rights reserved.
//

import UIKit
import MapKit
import CoreData

func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}

class PhotoAlbumViewController: UIViewController {

    // MARK: - Properties
    
    var pin: Pin!
    @IBOutlet weak var mapSnapshot: UIImageView!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var photos: [String]!
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapSnapshot.image = UIImage(data: pin.mapSnapshot)
        
        FlickrClient.sharedInstance().getPhotos(pin) { (success, photos, errorString) in
            if success {
                // call the NSFetchResults controller to fetch the photos that have been saved for this pin
                
                performUIUpdatesOnMain {
                    self.photos = photos
                    self.errorMessage.text = "Success"
                    self.errorMessage.hidden = false
                    print(self.photos)
                }
            
            } else {
                // display a label stating that no photos
                performUIUpdatesOnMain {
                    self.errorMessage.hidden = false
                    print(errorString)
                }
                
            }
        }
    }

    
    // TO DO: Check the old app from networking class that used flickr to find networking code
    
    
    
    
    
    
    
    // TO DO: Set up the networking though using separate networking class and MVC
    // TO DO: Add the photos to the Core Data framework
    // TO DO: Use NSFetchController functionality to drive the collection view
    // TO DO: Add activity indicator for each cell as it's loading
    // TO DO: Create "New Collection" functionality
    
    
}
