//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Chris Garvey on 4/10/16.
//  Copyright © 2016 Chris Garvey. All rights reserved.
//

import Foundation
import MapKit

extension FlickrClient {
    
    func getPhotos(pin: Pin, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        self.getImagesFromFlickr(pin) { (success, pageLimit, errorString) in
            
            if success {
            
                self.getImageFromFlickrBySearchWithPage(pin, pageLimit: pageLimit) { (success, errorString) in
                    
                    if success {
                        
                        completionHandler(success: true, errorString: nil)
                        
                    } else {
                        
                        completionHandler(success: false, errorString: errorString)
                    }
            
                }
        
        
            } else {
                
                completionHandler(success: false, errorString: errorString)
                
            }
        }
    
    }
    
}
