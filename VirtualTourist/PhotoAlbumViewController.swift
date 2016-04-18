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


/* Set reuse identifier constant for use in this file only */
private let reuseIdentifier = "PhotoCollectionViewCell"

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, UIViewControllerPreviewingDelegate {

    
    // MARK: - Properties
    
    var pin: Pin!
    @IBOutlet weak var mapSnapshot: UIImageView!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    
    /* Variable property to keep track of selected photos */
    var selectedPhotos = [Photo]()
    
    /* Variable properties to keep track of insertions, deletions, and updates */
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    /* Variable for photo selected with 3D Touch */
    var previewPhoto: Photo?
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Perform the fetch */
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        fetchedResultsController.delegate = self
        
        /* Check for 3D Touch support */
        // citation: http://www.the-nerd.be/2015/10/06/3d-touch-peek-and-pop-tutorial/
        if (traitCollection.forceTouchCapability == .Available) {
            
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        mapSnapshot.image = pin.mapSnapshot
        
        /* If a pin has no associated photos, begin the download of new photos */
        if pin.photos.isEmpty {
            downloadNewPhotoCollection()
        }
    }

    
    // MARK: - Action
    
    @IBAction func bottomButtonClicked(sender: UIBarButtonItem) {
        
        /* If no photos have been selected, then delete them all and download new ones */
        if selectedPhotos.isEmpty {
            
            /* This method has the pin delete all of its photos along with the underlying files in the Documents directory */
            pin.deleteAllPhotos()
            downloadNewPhotoCollection()
            
        } else {
            
            /* Otherwise, the pin deletes just the selected photos and its underlying files */
            pin.deleteSelectedPhotos(selectedPhotos)
            selectedPhotos = [Photo]()
            updateBottomButton()
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
        
        /* If the photo is already in the selectedPhotos array when the user selects the cell, remove the photo from the array */
        if let index = selectedPhotos.indexOf(photo) {
            selectedPhotos.removeAtIndex(index)
        } else {
            /* Otherwise, add the photo into the array */
            selectedPhotos.append(photo)
        }
        
        /* Configure the cell again to reflect its new selected or unselected status */
        configureCell(cell, photo: photo)
        
        /* Update the bottom button to reflect whether a new collection should be added or selected items removed */ 
        updateBottomButton()
    }
    
    
    // MARK: Configure Cell
    
    func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
        cell.backgroundColor = UIColor.blackColor()
        
        /* If there's no image associated with the photo, then download it */
        if photo.photoImage == nil {
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
            
        } else {
            /* Use the image that is already stored either in the cache or on the hard drive */
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
   
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            print("Insert an item")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        }
    }
    
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
            
            /* If for some reason the photo locations cannot be downloaded, state why in error message */
            if success == false {
                performUIUpdatesOnMain {
                    self.errorMessage.text = errorString
                    self.errorMessage.hidden = false
                }
            }
        }
    }
    
    func updateBottomButton() {
        if selectedPhotos.count > 0 {
            bottomButton.title = "Remove Selected Photos"
        } else {
            bottomButton.title = "New Collection"
        }
    }
    
    
    // MARK: - 3D Touch Functionality
    
    // MARK: Segue Method
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if (segue.identifier == "sgPhotoDetail") {
            let vc = segue.destinationViewController as! PhotoDetailViewController
            vc.photo = previewPhoto!
        }
        
    }

    
    // MARK: UIViewControllerPreviewingDelegate Methods
    
    // citation: https://tisunov.github.io/2015/11/03/3d-touch-peek-and-pop-with-custom-collectionviewlayout.html
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        var detailVC: PhotoDetailViewController?
        
        guard let layoutAttributes = collectionView!.collectionViewLayout.layoutAttributesForElementsInRect(collectionView!.bounds) else { return nil }
        
        for attributes in layoutAttributes {
            let point = collectionView!.convertPoint(location, fromView: collectionView!.superview)
            
            if attributes.representedElementKind == nil && CGRectContainsPoint(attributes.frame, point) {
                
                previewingContext.sourceRect = collectionView!.convertRect(attributes.frame, toView: collectionView!.superview)
                
                detailVC = storyboard?.instantiateViewControllerWithIdentifier("PhotoDetailViewController") as? PhotoDetailViewController
                previewPhoto = (fetchedResultsController.objectAtIndexPath(attributes.indexPath) as! Photo)
                detailVC!.photo = previewPhoto
                detailVC!.pin = pin
                
                detailVC!.preferredContentSize = CGSize(width: 0.0, height: 300)
                
                break
            }
        }
        
        return detailVC
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        
        showViewController(viewControllerToCommit, sender: self)

    }
    
}
