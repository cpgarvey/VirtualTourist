//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Chris Garvey on 4/9/16.
//  Copyright © 2016 Chris Garvey. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    // MARK: - Constants
    
    struct Constants {
        
        /* URLs */
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest"
        
        /* Key */
        static let API_KEY = "ENTER_YOUR_API_KEY_HERE"



        
        /* Method Arguments */
        static let METHOD_NAME = "flickr.photos.search"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let PER_PAGE = "21" // return just 21 images per page
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
        
    }
        
}