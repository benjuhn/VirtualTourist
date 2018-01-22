//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Ben Juhn on 8/1/17.
//  Copyright © 2017 Ben Juhn. All rights reserved.
//

import UIKit

// MARK: - Flickr Constants

struct FlickrConstants {
    
    // MARK: Flickr API
    struct API {
        static let Scheme = "https"
        static let Host = "api.flickr.com"
        static let Path = "/services/rest"
    }
    
    // MARK: Flickr BBox
    struct BBox {
        static let HalfWidth = 0.2
        static let HalfHeight = 0.2
        static let LatRange = (-90.0, 90.0)
        static let LonRange = (-180.0, 180.0)
    }
    
    // MARK: Flickr Parameter Keys
    struct ParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let Page = "page"
    }
    
    // MARK: Flickr Parameter Values
    struct ParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "15608e7a0a75ca515508143d2c4fe775"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        static let GalleryID = "5704-72157622566655097"
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
    }
    
    // MARK: Flickr Response Keys
    struct ResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    // MARK: Flickr Response Values
    struct ResponseValues {
        static let OKStatus = "ok"
    }
    
}
