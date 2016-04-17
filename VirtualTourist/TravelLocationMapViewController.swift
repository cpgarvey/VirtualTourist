//
//  TravelLocationMapViewController.swift
//  VirtualTourist
//
//  Created by Chris Garvey on 4/4/16.
//  Copyright © 2016 Chris Garvey. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationMapViewController: UIViewController, MKMapViewDelegate {

    
    // MARK: - Properties
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editModeView: UIView!
    @IBOutlet weak var editModeText: UILabel!
    
    var inEditMode: Bool!
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        restoreMapRegion(false)
        
        mapView.delegate = self
        
        inEditMode = false
        editModeView.hidden = true
        editModeText.hidden = true
        
        /* Set up the long press gesture recognizer to drop pins */
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationMapViewController.dropPin(_:)))
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)
    
        /* Add persisted pins to map */
        mapView.addAnnotations(fetchAllPins())

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        /* Set title in the navigation bar */
        title = "Virtual Tourist"
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        /* Set title to change the navigation back button in PhotoAlbumViewController */
        title = "Back To Map"
    }
    
    @IBAction func toggleEditMode(sender: UIBarButtonItem) {
        
        if !inEditMode {
            sender.title = "Done"
            editModeView.hidden = false
            editModeText.hidden = false
        } else {
            sender.title = "Edit"
            editModeView.hidden = true
            editModeText.hidden = true
        }
        
        inEditMode = !inEditMode
        
    }
    
    // MARK: - Helper Functions
    
    func fetchAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch _ {
            return [Pin]()
        }
    }
    
    // citation: http://juliusdanek.de/blog//coding/2015/07/14/persistent-pins-tutorial/
    func dropPin(gestureRecognizer: UIGestureRecognizer) {
        
        let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
        let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
        
        if UIGestureRecognizerState.Began == gestureRecognizer.state {
            
            let pin = Pin(annotationLatitude: touchMapCoordinate.latitude, annotationLongitude: touchMapCoordinate.longitude, context: self.sharedContext)
                self.mapView.addAnnotation(pin)
            }
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        if inEditMode == false {
            
            let pin = view.annotation as! Pin
            let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
            controller.pin = pin
            self.navigationController!.pushViewController(controller, animated: true)
            
        } else {
            
            let pin = view.annotation as! Pin
            
            /* Delete all photo data in cache and hard drive related to pin */
            pin.deleteAllPhotoImages()
            pin.deleteSnapshot()
            
            /* Delete the pin object from Core Data */
            sharedContext.deleteObject(pin)
            
            /* Remove the annotation from the map */
            mapView.removeAnnotation(pin)
            
            /* Save the context */
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
    }
    
    
    // MARK: - NSKeyedArchiver Persistence Property and Helper Methods
    
    /* convenience property to return the file path for where the map location is stored */
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    func saveMapRegion() {
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            print("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    
    // MARK: - MKMapViewDelegate Method
    
    /* delegate method notifies the view controller when the map view changes so that the map location can be saved */
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    
    
}

