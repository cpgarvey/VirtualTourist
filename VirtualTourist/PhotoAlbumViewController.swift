//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Chris Garvey on 4/5/16.
//  Copyright © 2016 Chris Garvey. All rights reserved.
//

import UIKit
import MapKit


class PhotoAlbumViewController: UIViewController {

    // MARK: - Properties
    
    var pin: Pin!
    @IBOutlet weak var mapSnapshot: UIImageView!
    
    
    
    // MARK: - Life Cycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapSnapshot.image = UIImage(data: pin.mapSnapshot)
    }

    
}
