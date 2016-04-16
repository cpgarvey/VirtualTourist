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

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

    // MARK: - Properties
    
    var pin: Pin!
    @IBOutlet weak var mapSnapshot: UIImageView!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedPhotos = [Photo]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Perform the fetch */
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        mapSnapshot.image = UIImage(data: pin.mapSnapshot)
        
        if pin.photos.isEmpty {
            downloadNewPhotoCollection()
        }
    }

    // MARK: - Action
    
    @IBAction func bottomButtonClicked(sender: UIBarButtonItem) {
        
        if selectedPhotos.isEmpty {
            deleteAllPhotos()
            downloadNewPhotoCollection()
        } else {
            deleteSelectedPhotos()
        }
    }
    
    
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    
    // MARK: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    
    // MARK: - Collection View 
    
    // MARK: Layout
    
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
   
    
    // MARK: Data Source Protocol Methods - Getting Item and Section Metrics
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    
    // MARK: Data Source Protocol Method - Getting Views For Items
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
       
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        configureCell(cell, photo: photo)
        
        return cell
        
    }
    
    // MARK: Collection View Delegate Protocol Method - Managing the Selected Cells
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedPhotos.indexOf(photo) {
            selectedPhotos.removeAtIndex(index)
        } else {
            selectedPhotos.append(photo)
        }
        
        // Then reconfigure the cell
        configureCell(cell, photo: photo)
        
        // And update the buttom button
        updateBottomButton()
    }
    
    // MARK: Configure Cell
    
    func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
        cell.backgroundColor = UIColor.blackColor()
        
        
        if photo.photoImage == nil {  // then download the image using the photoPath
            cell.photoImageView.image = UIImage(named: "placeholder")
            cell.activityIndicator.startAnimating()
            
            FlickrClient.sharedInstance().downloadPhoto(photo) { (success, errorString) in
                if success {
                    performUIUpdatesOnMain {
                        cell.photoImageView?.image = photo.photoImage
                        cell.activityIndicator.stopAnimating()
                    }
                } else {
                    performUIUpdatesOnMain {
                        cell.photoImageView.image = UIImage(named: "placeholder")
                        cell.activityIndicator.stopAnimating()
                        print(errorString)
                    }
                }
            }
            
        }
        
        else { // use the image that is already stored either in the cache or on the hard drive
            
            performUIUpdatesOnMain {
                cell.photoImageView?.image = photo.photoImage
            }
        }
        
        /* Toggle the transparency of the cell depending on whether the photo appears in the selecterPhotos array */
        if let _ = selectedPhotos.indexOf(photo) {
            cell.alpha = 0.25
        } else {
            cell.alpha = 1.0
        }
    
    }
    
    
    // MARK: - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            print("Insert an item")
            // Here we are noting that a new Color instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            // Here we are noting that a Color instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            // We don't expect Color instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an images is downloaded from
            // Flickr in the Virtual Tourist app
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    
    // MARK: - Helper Functions
    
    func downloadNewPhotoCollection() {
        
        FlickrClient.sharedInstance().getPhotos(pin) { (success, errorString) in
            if success == false {
                // display a label stating that no photos
                performUIUpdatesOnMain {
                    self.errorMessage.text = errorString
                    self.errorMessage.hidden = false
                }
            }
        }
    }
    
    func deleteAllPhotos() {
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            FlickrClient.Caches.imageCache.deleteImage(photo.photoID)
            sharedContext.deleteObject(photo)
            
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
    }
    
    func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for photo in selectedPhotos {
            photosToDelete.append(photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
            FlickrClient.Caches.imageCache.deleteImage(photo.photoID)
        }
        
        selectedPhotos = [Photo]()
        CoreDataStackManager.sharedInstance().saveContext()
        updateBottomButton()
    }
    
    
    func updateBottomButton() {
        if selectedPhotos.count > 0 {
            bottomButton.title = "Remove Selected Photos"
        } else {
            bottomButton.title = "New Collection"
        }
    }
    
    
}
