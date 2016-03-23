//
//  YQL.swift
//  YahooServicesDemo
//
//  Created by dungvh on 3/9/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import Foundation
import Alamofire
let APIBaseQuery = "https://query.yahooapis.com/v1/public/yql"
let kFormat = "json"
let kEnv = "store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
let kKeyFlickr = "657c3c9c46f59732c50c2449edab58e7"
let kSecrectFlickr = "6b4ee75f61e053f2"
let kNumberItem = 80

let APIFlickrBase = "https://api.flickr.com/services/rest/"

enum Endpoint:URLRequestConvertible{
    
    case Weather(String)
    case PhotosInteresting
    case PhotosFromFlickrOriginal(Int)
    
    
    var URLRequest: NSMutableURLRequest{
        var parameters:[String:AnyObject]?
        var path = APIBaseQuery
        switch (self){
        case .Weather(let text):
            parameters = [String:AnyObject]()
            let str = "select * from weather.forecast where woeid in (select woeid from geo.places(1) where text=\"\(text)\")"
            parameters!["q"] = str.stringByRemovingPercentEncoding ?? ""
            parameters!["format"] = kFormat
            parameters!["env"] = kEnv
        case .PhotosInteresting:
            parameters = [String:AnyObject]()
            let str = "select * from flickr.photos.interestingness(\(kNumberItem)) where api_key=\"\(kKeyFlickr)\" and extras=\"url_t\""
            parameters!["q"] = str.stringByRemovingPercentEncoding ?? ""
            parameters!["format"] = kFormat
            parameters!["env"] = kEnv
        case PhotosFromFlickrOriginal(let page):
            path = APIFlickrBase
            parameters = [String:AnyObject]()
            parameters!["method"] = "flickr.interestingness.getList"
            parameters!["api_key"] = kKeyFlickr
            parameters!["format"] = kFormat
            parameters!["extras"] = "url_t"
            parameters!["page"] = page
            parameters!["per_page"] = kNumberItem
        }
        
        let URLRequest = NSURLRequest(URL: NSURL(string: path)!)
        let encoding = ParameterEncoding.URL
        return encoding.encode(URLRequest, parameters: parameters).0
    }
    
}