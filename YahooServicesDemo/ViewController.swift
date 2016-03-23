//
//  ViewController.swift
//  YahooServicesDemo
//
//  Created by dungvh on 3/9/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import UIKit
import Alamofire
import WebKit
import ObjectMapper
import Haneke

enum ResultType:ErrorType {
    case Success(r: NSData)
    case Error(e: ErrorType)
}

class ViewController: UIViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var collectionView: UICollectionView!
    var webView:WKWebView!
    var response:PhotoResponse?
    lazy var collectionViewSizeCalculator:GreedoCollectionViewLayout = {
        let layout:GreedoCollectionViewLayout = GreedoCollectionViewLayout(collectionView: self.collectionView)
        layout.dataSource = self
        return layout
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupView()
        
        requestPhotosInteresting { (inner) -> () in
            do{
                self.response = try inner()
                self.collectionView.reloadData()
            }catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        
        
//        requestInterestingFromBaseUrl()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupView(){
        collectionViewSizeCalculator.rowMaximumHeight = 100
        webView = WKWebView(frame: CGRectZero)
        webView.backgroundColor = UIColor.blackColor()
        webView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(webView)
        let centerX = NSLayoutConstraint(item: webView, attribute: .CenterX, relatedBy: .Equal, toItem: contentView, attribute: .CenterX, multiplier: 1.0, constant: 0)
        let centerY = NSLayoutConstraint(item: webView, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1.0, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: webView, attribute: .Width, relatedBy: .Equal, toItem: contentView, attribute: .Width, multiplier: 1.0, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: webView, attribute: .Height, relatedBy: .Equal, toItem: contentView, attribute: .Height, multiplier: 1.0, constant: 0)
        
        contentView.addConstraints([centerX,centerY,widthConstraint,heightConstraint])
        
    }
    
    func asyncRequestThrowError(city:String?,completion:(inner:() throws -> NSData) -> ()){
        guard let value = city where value.characters.count > 0 else {
            completion(inner:{throw NSError(domain: "com.weather", code: 484, userInfo: [NSLocalizedDescriptionKey:"No City to Search!!!!"])})
            return
        }
        
        Manager.sharedInstance.request(Endpoint.Weather(value)).response { (_, _, data, error) -> Void in
            guard error == nil else {
                completion(inner: { throw error!})
                return
            }
            
            guard let dataResponse = data else{
                completion(inner: { throw NSError(domain: "com.weather", code: 48875, userInfo: [NSLocalizedDescriptionKey:"No Data!!!!"])})
                return
            }
            
            completion(inner: {return dataResponse})
        }
    }
    
    
//    func requestInterestingFromBaseUrl()
//    {
//        Manager.sharedInstance.request(Endpoint.PhotosFromFlickrOriginal(1)).responseData { (response:Response<NSData,NSError>) -> Void in
//            var str = String(data: response.result.value!, encoding: NSUTF8StringEncoding)
//            str = str?.stringByReplacingOccurrencesOfString("jsonFlickrApi(", withString: "")
//            let index = str!.endIndex.advancedBy(-1)
//            str = str!.substringToIndex(index)
//           print("result : \(str!)")
//            
//            let json = try! NSJSONSerialization.JSONObjectWithData(str!.dataUsingEncoding(NSASCIIStringEncoding)!, options: [])
////
//            print("json : \(json)")
//            
//        }
//    }
    
    func searchWeatherCity(city:String?){
        asyncRequestThrowError(city) { (inner) -> () in
            do {
                let result = try inner()
                let Json = try NSJSONSerialization.JSONObjectWithData(result, options: .AllowFragments)
                let obj = Mapper<WeatherInfo>().map(Json)
                
                guard let html = obj?.html else {
                    throw NSError(domain: "com.weather", code: 154, userInfo: [NSLocalizedDescriptionKey:"No Web View"])
                }
                
                self.webView.loadHTMLString(html, baseURL: nil)
                
            } catch let error {
                print(error)
            }
        }
    }
    
    func requestPhotosInteresting(completion:(inner: () throws -> PhotoResponse?) -> ()){
        Manager.sharedInstance.request(Endpoint.PhotosInteresting).responseJSON { (response:Response<AnyObject,NSError>) -> Void in
            guard response.result.error == nil else{
                completion(inner: {throw response.result.error!})
                return
            }
            
            let objResponse = Mapper<PhotoResponse>().map(response.result.value)
            completion(inner: {return objResponse})
            
            
        }
    }
    
    
    @IBAction func tapBySearch(sender: AnyObject) {
        textField.resignFirstResponder()
        searchWeatherCity(textField.text)
        
    }
}

extension UICollectionViewCell{
    public override func prepareForReuse() {
        if let imageView = self.viewWithTag(200) as? UIImageView
        {
            imageView.image = nil
            imageView.hnk_cancelSetImage()
        }
    }
}


extension ViewController:UICollectionViewDataSource
{
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
        let item = self.response?.items?[indexPath.item]
        if let imageView = cell.viewWithTag(200) as? UIImageView , url = item?.urlPhoto() {
            imageView.hnk_setImageFromURL(url)
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.response?.count ?? 0
    }
    
}

extension ViewController:UICollectionViewDelegateFlowLayout{
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionViewSizeCalculator.sizeForPhotoAtIndexPath(indexPath)
    }
}

// MARK: --- Calculate size item
extension ViewController:GreedoCollectionViewLayoutDataSource{
    func greedoCollectionViewLayout(layout: GreedoCollectionViewLayout, originalImageSizeAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let numberItem = self.response?.items?.count ?? 0
        if indexPath.item < numberItem {
            let item = self.response?.items?[indexPath.item]
            if let width = item?.width_t , height = item?.height_t
            {
                return CGSizeMake(CGFloat(width), CGFloat(height))
            }
        }
        
        return CGSizeMake(0.1, 0.1)
    }
}

class WeatherInfo: Mappable {
    var html:String?
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        html <- (map["query.results.channel.item.description"],TransformOf<String,String>(fromJSON: { (str) -> String? in
            let result = str?.stringByReplacingOccurrencesOfString("'\\'", withString: "", options: .LiteralSearch, range: nil)
            return result
            }, toJSON: { (str) -> String? in
                return nil
        }) )
    }
    
}

class PhotoItem:Mappable{
    var farm:String?
    var identifier:String?
    var owner:String?
    var secret:String?
    var server:String?
    var title:String?
    var width_t:Int?
    var height_t:Int?
    required init?(_ map: Map) {
        
    }
    
    func urlPhoto() -> NSURL?{
        guard let farm = self.farm,server = self.server,identifier = self.identifier,secret = self.secret else{
            return nil
        }
        let path = "https://farm\(farm).staticflickr.com/\(server)/\(identifier)_\(secret).jpg"
        let url = NSURL(string: path)
        return url
    }
    
    
    func mapping(map: Map) {
        farm <- map["farm"]
        identifier <- map["id"]
        owner <- map["owner"]
        secret <- map["secret"]
        server <- map["server"]
        title <- map["title"]
        width_t <- (map["width_t"],TransformOf<Int,String>(fromJSON: { (str) -> Int? in
            guard let vl = str else{
                return nil
            }
                return Int(vl)
            }, toJSON: { (value) -> String? in
                return nil
        }))
        height_t <- (map["height_t"],TransformOf<Int,String>(fromJSON: { (str) -> Int? in
            guard let vl = str else{
                return nil
            }
            return Int(vl)
            }, toJSON: { (value) -> String? in
                return nil
        }))

        
    }
}
class PhotoResponse:Mappable {
    var count:Int?
    var items:[PhotoItem]?
    var created:String?
    var lang:String?
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map){
        count <- map["query.count"]
        items <- map["query.results.photo"]
        created <- map["query.created"]
        lang <- map["query.lang"]
    }
}

