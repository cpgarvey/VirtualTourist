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

/* Set reuse identifier constant for use in this file only */
private let reuseIdentifier = "PhotoCollectionViewCell"

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - Properties
    
    var pin: Pin!
    @IBOutlet weak var mapSnapshot: UIImageView!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var photos = [String]()
    
    
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapSnapshot.image = UIImage(data: pin.mapSnapshot)
        
        FlickrClient.sharedInstance().getPhotos(pin) { (success, photos, errorString) in
            if success {
                // call the NSFetchResults controller to fetch the photos that have been saved for this pin
                
                performUIUpdatesOnMain {
                    self.photos = photos!
                    print(self.photos)
                    self.collectionView!.reloadData()
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

    
    // MARK: - Collection View Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with 5 points space in between.
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        let width = floor((self.collectionView.frame.size.width-10)/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
   
    
    
    // MARK: - Collection View Data Source Protocol Method - Getting Item and Section Metrics
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    
    // MARK: - Collection View Data Source Protocol Method - Getting Views For Items
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("Reached cellForItemAtIndexPath")
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        cell.backgroundColor = UIColor.blackColor()
        cell.activityIndicator.startAnimating()
        
        // citation: http://stackoverflow.com/questions/28868894/swift-url-reponse-is-nil
        let session = NSURLSession.sharedSession()
        let imageURL = NSURL(string: photos[indexPath.row])
        
        let sessionTask = session.dataTaskWithURL(imageURL!) { data, response, error in
            performUIUpdatesOnMain {
                cell.photoImageView?.image = UIImage(data: data!)
                cell.activityIndicator.stopAnimating()
            }
        }
        
        sessionTask.resume()
        return cell
        
    }
    
    // MARK: - Collection View Delegate Protocol Method - Managing the Selected Cells
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // TO DO: have the photo selected and then deleted if necessary
    }
    
    
   
    // TO DO: Add the photos to the Core Data framework
    // TO DO: Use NSFetchController functionality to drive the collection view
    // TO DO: Create "New Collection" functionality
    
    
}
