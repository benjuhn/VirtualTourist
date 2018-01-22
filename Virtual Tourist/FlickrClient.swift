//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Ben Juhn on 8/1/17.
//  Copyright © 2017 Ben Juhn. All rights reserved.
//

import UIKit
import MapKit

class FlickrClient {
    
    static let shared = FlickrClient()
    private init() {}
    
    func findPhoto(_ coordinate: CLLocationCoordinate2D, _ photoIndex: Int?, completionHandler: @escaping (_ image: Data?, _ title: String?, _ error: String?) -> Void) {
        let methodParameters = createParameters(coordinate)
        var pageNumber: Int? = nil
        if photoIndex != nil {
            pageNumber = 1
        }
        displayImageFromFlickrBySearch(methodParameters as [String:AnyObject], pageNumber, photoIndex) {
            (image, title, error) in
            if error != nil {
                completionHandler(nil, nil, error)
                return
            } else {
                completionHandler(image, title, nil)
            }
        }
    }
    
    func findNumberOfPhotos(_ coordinate: CLLocationCoordinate2D, completionHandler: @escaping(_ imageCount: Int?, _ error: String?) -> Void) {
        
        let methodParameters = createParameters(coordinate)
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters as [String:AnyObject]))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(nil, "There was an error with your request: \(error!)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandler(nil, "Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandler(nil, "No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                completionHandler(nil, "Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[FlickrConstants.ResponseKeys.Status] as? String, stat == FlickrConstants.ResponseValues.OKStatus else {
                completionHandler(nil, "Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult[FlickrConstants.ResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandler(nil, "Cannot find key '\(FlickrConstants.ResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "total" key in the photosDictionary? */
            // Extra step needed for converting value from "total" key for mysterious reasons
            guard let total = photosDictionary[FlickrConstants.ResponseKeys.Total] as? String else {
                completionHandler(nil, "Cannot find key '\(FlickrConstants.ResponseKeys.Total)' in \(photosDictionary)")
                return
            }
            guard let totalPhotos = Int(total) else {
                completionHandler(nil, "Cannot convert total to integer")
                return
            }
            let maxPhotos = min(totalPhotos, 21)
            completionHandler(maxPhotos, nil)
        }
        
        task.resume()
    }
    
    // MARK: Flickr API
    
    private func displayImageFromFlickrBySearch(_ inputParameters: [String:AnyObject], _ pageNumber: Int?, _ photoIndex: Int?, completionHandler: @escaping (_ image: Data?, _ title: String?, _ error: String?) -> Void) {
        
        var methodParameters = inputParameters
        if pageNumber != nil {
            // add the page to the method's parameters
            methodParameters[FlickrConstants.ParameterKeys.Page] = pageNumber as AnyObject?
        }
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(nil, nil, "There was an error with your request: \(error!)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandler(nil, nil, "Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandler(nil, nil, "No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                completionHandler(nil, nil, "Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[FlickrConstants.ResponseKeys.Status] as? String, stat == FlickrConstants.ResponseValues.OKStatus else {
                completionHandler(nil, nil, "Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult[FlickrConstants.ResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandler(nil, nil, "Cannot find key '\(FlickrConstants.ResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            if pageNumber == nil {
                /* GUARD: Is "pages" key in the photosDictionary? */
                guard let totalPages = photosDictionary[FlickrConstants.ResponseKeys.Pages] as? Int else {
                    completionHandler(nil, nil, "Cannot find key '\(FlickrConstants.ResponseKeys.Pages)' in \(photosDictionary)")
                    return
                }
                
                // pick a random page!
                let pageLimit = min(totalPages, 40)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                self.displayImageFromFlickrBySearch(methodParameters, randomPage, nil) {
                    (image, title, error) in
                    if error != nil {
                        completionHandler(nil, nil, error)
                        return
                    } else {
                        completionHandler(image, title, nil)
                    }
                }
            } else {
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary[FlickrConstants.ResponseKeys.Photo] as? [[String:AnyObject]] else {
                    completionHandler(nil, nil, "Cannot find key '\(FlickrConstants.ResponseKeys.Photo)' in \(photosDictionary)")
                    return
                }
                
                if photosArray.count == 0 {
                    completionHandler(nil, nil, "No Photos Found. Search Again.")
                    return
                } else {
                    var randomPhotoIndex = Int()
                    if photoIndex == nil {
                        randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                    } else {
                        randomPhotoIndex = photoIndex!
                    }
                    let photoDictionary = photosArray[randomPhotoIndex] as [String:AnyObject]
                    let photoTitle = photoDictionary[FlickrConstants.ResponseKeys.Title] as? String
                    
                    /* GUARD: Does our photo have a key for 'url_m'? */
                    guard let imageUrlString = photoDictionary[FlickrConstants.ResponseKeys.MediumURL] as? String else {
                        completionHandler(nil, nil, "Cannot find key '\(FlickrConstants.ResponseKeys.MediumURL)' in \(photoDictionary)")
                        return
                    }
                    
                    // if an image exists at the url, set the image and title
                    let imageURL = URL(string: imageUrlString)
                    if let imageData = try? Data(contentsOf: imageURL!) {
                        DispatchQueue.main.async {
                            // Send image data & title to collection view cell, save in core data
                            completionHandler(imageData, photoTitle, nil)
                        }
                    } else {
                        completionHandler(nil, nil, "Image does not exist at \(imageURL!)")
                    }
                }
            }
            
        }
        
        // start the task!
        task.resume()
    }
    
    // MARK: Helper functions
    
    private func createParameters(_ coordinate: CLLocationCoordinate2D) -> [String:String] {
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        let minimumLon = max(longitude - FlickrConstants.BBox.HalfWidth, FlickrConstants.BBox.LonRange.0)
        let minimumLat = max(latitude - FlickrConstants.BBox.HalfHeight, FlickrConstants.BBox.LatRange.0)
        let maximumLon = min(longitude + FlickrConstants.BBox.HalfWidth, FlickrConstants.BBox.LonRange.1)
        let maximumLat = min(latitude + FlickrConstants.BBox.HalfHeight, FlickrConstants.BBox.LatRange.1)
        let bboxString = "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        let methodParameters = [
            FlickrConstants.ParameterKeys.Method: FlickrConstants.ParameterValues.SearchMethod,
            FlickrConstants.ParameterKeys.APIKey: FlickrConstants.ParameterValues.APIKey,
            FlickrConstants.ParameterKeys.BoundingBox: bboxString,
            FlickrConstants.ParameterKeys.SafeSearch: FlickrConstants.ParameterValues.UseSafeSearch,
            FlickrConstants.ParameterKeys.Extras: FlickrConstants.ParameterValues.MediumURL,
            FlickrConstants.ParameterKeys.Format: FlickrConstants.ParameterValues.ResponseFormat,
            FlickrConstants.ParameterKeys.NoJSONCallback: FlickrConstants.ParameterValues.DisableJSONCallback
        ]
        return methodParameters
    }
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = FlickrConstants.API.Scheme
        components.host = FlickrConstants.API.Host
        components.path = FlickrConstants.API.Path
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
