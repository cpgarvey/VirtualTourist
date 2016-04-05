//
//  TravelLocationMapViewController.swift
//  VirtualTourist
//
//  Created by Chris Garvey on 4/4/16.
//  Copyright © 2016 Chris Garvey. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationMapViewController: UIViewController, MKMapViewDelegate {

    // MARK: - Property
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        restoreMapRegion(false)
        
        mapView.delegate = self
        
        /* set up the long press gesture recognizer to drop pins */
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationMapViewController.dropPin(_:)))
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)

    }
    
    func dropPin(gestureRecognizer: UIGestureRecognizer) {
        
        let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
        let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
        
        if UIGestureRecognizerState.Began == gestureRecognizer.state {
            let pin = Pin(annotationLatitude: touchMapCoordinate.latitude, annotationLongitude: touchMapCoordinate.longitude)
            mapView.addAnnotation(pin)
        }
    }
    
    
    
    // MARK: - Persistence Property and Helper Methods
    
    /* convenience property to return the file path
     for where the map location is stored */
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
    
    /* delegate method notifies the view controller when the map view changes
     so that the map location can be saved */
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
}

