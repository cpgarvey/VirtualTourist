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
    
    func getPhotos(pin: Pin, completionHandler: (success: Bool, photos: [String]?, errorString: String?) -> Void) {
        
        self.getImagesFromFlickr(pin) { (success, pageLimit, errorString) in
            
            if success {
            
                self.getImageFromFlickrBySearchWithPage(pin, pageLimit: pageLimit) { (success, photos, errorString) in
                    
                    if success {
                        
                        completionHandler(success: true, photos: photos, errorString: nil)
                        
                    } else {
                        
                        completionHandler(success: false, photos: nil, errorString: errorString)
                    }
            
                }
        
        
            } else {
                
                completionHandler(success: false, photos: nil, errorString: errorString)
                
            }
        }
    
    }
    
}
