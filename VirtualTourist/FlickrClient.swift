//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Chris Garvey on 4/9/16.
//  Copyright © 2016 Chris Garvey. All rights reserved.
//

import Foundation
import MapKit

// eventually will need to set up a convenience method that will check first to see if anything gets returned (one page or more), if so then continue on to pulling the next page 

class FlickrClient: NSObject {
    
    /* Shared Session */
    var session = NSURLSession.sharedSession()
    
    func getImagesFromFlickr(pin: MKAnnotation, completionHandler: (success: Bool, pageLimit: Int, errorString: String?) -> Void) {
        
        let methodArguments = [
            "method": Constants.METHOD_NAME,
            "api_key": Constants.API_KEY,
            "bbox": createBoundingBoxString(pin),
            "safe_search": Constants.SAFE_SEARCH,
            "extras": Constants.EXTRAS,
            "format": Constants.DATA_FORMAT,
            "nojsoncallback": Constants.NO_JSON_CALLBACK,
            "per_page": Constants.PER_PAGE
        ]
        
        let session = NSURLSession.sharedSession()
        let url = constructFlickrURL(methodArguments)
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find keys 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary["pages"] as? Int else {
                print("Cannot find key 'pages' in \(photosDictionary)")
                return
            }
            
            /* Set the page limit */
            let pageLimit = min(totalPages, 40)
            completionHandler(success: true, pageLimit: pageLimit, errorString: nil)
        }
        
        task.resume()
    }
    
    func getImageFromFlickrBySearchWithPage(pin: MKAnnotation, pageLimit: Int, completionHandler: (success: Bool, photos: [String]?, errorString: String?) -> Void) {
        
        let methodArguments = [
            "method": Constants.METHOD_NAME,
            "api_key": Constants.API_KEY,
            "bbox": createBoundingBoxString(pin),
            "safe_search": Constants.SAFE_SEARCH,
            "extras": Constants.EXTRAS,
            "format": Constants.DATA_FORMAT,
            "nojsoncallback": Constants.NO_JSON_CALLBACK,
            "per_page": Constants.PER_PAGE
        ]
        
        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        // we'll need to check if we're reaching the pageLimit as we iterate through the pages; if not, then continue to next line
        withPageDictionary["page"] = "1" // we'll need to iterate this number based on how many times we've searched for photos
        
        let session = NSURLSession.sharedSession()
        let url = constructFlickrURL(withPageDictionary)
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find key 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "total" key in photosDictionary? */
            guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                print("Cannot find key 'total' in \(photosDictionary)")
                return
            }
            
            if totalPhotosVal > 0 {
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find key 'photo' in \(photosDictionary)")
                    return
                }
                
                var photoUrlArray = [String]()
                
                for photo in photosArray {
                    
                    /* GUARD: Does our photo have a key for 'url_m'? */
                    guard let imageUrlString = photo["url_m"] as? String else {
                        print("Cannot find key 'url_m' in \(photo)")
                        completionHandler(success: false, photos: nil, errorString: "Problem with a photo URL")
                        return
                    }
                    
                    photoUrlArray.append(imageUrlString)
                }
                
//                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
//                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
//                
//                
//                /* GUARD: Does our photo have a key for 'url_m'? */
//                guard let imageUrlString = photoDictionary["url_m"] as? String else {
//                    print("Cannot find key 'url_m' in \(photoDictionary)")
//                    return
//                }
//                
//                // the following is the downloading part... we want that to occur in the photo album view controller, so this needs to be moved
//                let imageURL = NSURL(string: imageUrlString)
//                if let imageData = NSData(contentsOfURL: imageURL!) {
//                    dispatch_async(dispatch_get_main_queue(), {
//                        
//                        self.defaultLabel.alpha = 0.0
//                        self.photoImageView.image = UIImage(data: imageData)
//                        
//                        if methodArguments["bbox"] != nil {
//                            if let photoTitle = photoTitle {
//                                self.photoTitleLabel.text = "\(self.getLatLonString()) \(photoTitle)"
//                            } else {
//                                self.photoTitleLabel.text = "\(self.getLatLonString()) (Untitled)"
//                            }
//                        } else {
//                            self.photoTitleLabel.text = photoTitle ?? "(Untitled)"
//                        }
//                    })
//                } else {
//                    print("Image does not exist at \(imageURL)")
//                }
//            } else {
//                dispatch_async(dispatch_get_main_queue(), {
//                    self.photoTitleLabel.text = "No Photos Found. Search Again."
//                    self.defaultLabel.alpha = 1.0
//                    self.photoImageView.image = nil
//                })
            
                completionHandler(success: true, photos: photoUrlArray, errorString: nil)
            }
        }
        
        task.resume()
    }
    
    
    
    // MARK: - Lat/Lon Manipulation
    
    func createBoundingBoxString(pin: MKAnnotation) -> String {
        
        let latitude = pin.coordinate.latitude
        let longitude = pin.coordinate.longitude
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - Constants.BOUNDING_BOX_HALF_WIDTH, Constants.LON_MIN)
        let bottom_left_lat = max(latitude - Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MIN)
        let top_right_lon = min(longitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LON_MAX)
        let top_right_lat = min(latitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    
    /* Construct a Flickr URL from parameters */
    func constructFlickrURL(parameters: [String:AnyObject]?) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.ApiScheme
        components.host = Constants.ApiHost
        components.path = Constants.ApiPath
        components.queryItems = [NSURLQueryItem]()
        
        if parameters != nil {
            
            for (key, value) in parameters! {
                let queryItem = NSURLQueryItem(name: key, value: "\(value)")
                components.queryItems!.append(queryItem)
            }
            
        }
        
        return components.URL!
    }
    
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
    
}


