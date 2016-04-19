//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Chris Garvey on 4/9/16.
//  Copyright © 2016 Chris Garvey. All rights reserved.
//

import Foundation
import MapKit

import CoreData

class FlickrClient: NSObject {
    
    /* Shared Session */
    var session = NSURLSession.sharedSession()
    
    
    // MARK: - Flickr API Calls
    
    func getPhotos(pin: Pin, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
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
        
        /* Add the variable page argument to the method */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = String(pin.pageNumber)
        
        let session = NSURLSession.sharedSession()
        let url = constructFlickrURL(withPageDictionary)
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                completionHandler(success: false, errorString: "There was a network error with your request.")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                    completionHandler(success: false, errorString: "There was a network error with your request.")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                    completionHandler(success: false, errorString: "There was a network error with your request.")
                } else {
                    print("Your request returned an invalid response!")
                    completionHandler(success: false, errorString: "There was a network error with your request.")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                completionHandler(success: false, errorString: "There was a data error with your request.")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                completionHandler(success: false, errorString: "There was a data error with your request.")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                completionHandler(success: false, errorString: "There was an error with the Flickr service.")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find key 'photos' in \(parsedResult)")
                completionHandler(success: false, errorString: "There was an error reading the photo data.")
                return
            }
            
            /* GUARD: Is the "total" key in photosDictionary? */
            guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                print("Cannot find key 'total' in \(photosDictionary)")
                completionHandler(success: false, errorString: "There was an error reading the photo data.")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                print("Cannot find key 'photo' in \(photosDictionary)")
                completionHandler(success: false, errorString: "There was an error reading the photo data.")
                return
            }
            
            /* Use comparison tests to see what photos, if any, were returned */
            if photosArray.count == 0 && totalPhotosVal > 0 {
                completionHandler(success: false, errorString: "There are no more photos for this location.")
            } else if photosArray.count == 0 && totalPhotosVal == 0 {
                completionHandler(success: false, errorString: "There are no photos for this location.")
            } else {
                for photo in photosArray {
                    
                    /* GUARD: Does our photo have a key for 'url_m'? */
                    guard let imageUrlString = photo["url_m"] as? String else {
                        print("Cannot find key 'url_m' in \(photo)")
                        completionHandler(success: false, errorString: "There was an error reading the photo data.")
                        return
                    }
                    
                    /* GUARD: Does our photo have a key for 'id'? */
                    guard let photoID = photo["id"] as? String else {
                        print("Cannot find key 'id' in \(photo)")
                        completionHandler(success: false, errorString: "There was an error reading the photo data.")
                        return
                    }
                    
                    performUIUpdatesOnMain {
                    /* Create a new photo object */
                    let _ = Photo(pin: pin, photoID: photoID, photoPath: imageUrlString, context: self.sharedContext)
                    
                    /* Save the Core Data Context that includes the new photo object */
                    CoreDataStackManager.sharedInstance().saveContext()
                    }
                    
                }
                
                performUIUpdatesOnMain {
                /* If the download has been successful, increment the page number for the next network call */
                pin.pageNumber = pin.pageNumber + 1
                }
                /* Send back a success message to the caller through the completion handler */
                completionHandler(success: true, errorString: nil)
            }

        }
        
        task.resume()
    }
    
    func downloadPhoto(photo: Photo, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        // citation: http://stackoverflow.com/questions/28868894/swift-url-reponse-is-nil
        let session = NSURLSession.sharedSession()
        let imageURL = NSURL(string: photo.photoPath)
        
        let sessionTask = session.dataTaskWithURL(imageURL!) { data, response, error in
            
            /* GUARD: Was data returned? */
            guard let data = data else {
                completionHandler(success: false, errorString: error?.localizedDescription)
                return
            }
            
            performUIUpdatesOnMain {
            /* Add the downloaded photo image to the photo object */
            photo.photoImage = UIImage(data: data)
            }
            /* Send back a success message to the caller through the completion handler */
            completionHandler(success: true, errorString: nil)
            
        }

        sessionTask.resume()
    }
    
    
    // MARK: - Helper Functions
    
    /* Set the box boundaries of the search for the pin location */
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
    
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    
    // MARK: - Shared Class Instance
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
    
}


