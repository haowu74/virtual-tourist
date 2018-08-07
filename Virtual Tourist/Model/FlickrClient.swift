//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Hao Wu on 24/7/18.
//  Copyright © 2018 S&J. All rights reserved.
//

import Foundation

class FlickrClient {
    let ApiKey = "d385ff977003a2f2586eee316d1391c4"
    let searchUrl = "https://api.flickr.com/services/rest/?method=flickr.photos.search"
    let getInfoUrl = "https://api.flickr.com/services/rest/?method=flickr.photos.getInfo"

    // Singleton
    private init() {

    }
    
    static let shared = FlickrClient()
    
    // Flickr API to get photo info for a particular geographic position
    func GetPhotosFromGeo(_ lat: String, _ lon: String, _ radius: Int, _ completionHandler: @escaping (_ error: Error?, _ photoInfos: [PhotoInfo]) -> Void) {
        let requestStr = "\(searchUrl)&api_key=\(ApiKey)&lat=\(lat)&lon=\(lon)&radius=\(radius)&format=json&nojsoncallback=1"
        var request = URLRequest(url: URL(string: requestStr)!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            var photoInfos = [PhotoInfo]()
            if error != nil {
                completionHandler(error, photoInfos)
            } else {
                do {
                    let parsedResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String: AnyObject]
                    
                    if let results = parsedResult["photos"] {
                        let photos: [AnyObject] = results["photo"] as! [AnyObject]
                        for photo in photos {
                            let infoDict = photo as! [String: AnyObject]
                            let photoInfo = PhotoInfo(id: infoDict["id"] as! String,
                                                      owner: infoDict["owner"] as! String,
                                                      secret: infoDict["secret"] as! String,
                                                      server: infoDict["server"] as! String,
                                                      farm: infoDict["farm"] as! Int,
                                                      title: infoDict["title"] as! String)
                            photoInfos.append(photoInfo)
                        }
                    }
                    completionHandler(nil, photoInfos)
                } catch {
                    completionHandler(nil, photoInfos)
                }
            }
        }
        task.resume()
    }
    
    // Extract the Photo Url from the info returned from Flickr API
    func GetPhotoUrl(_ photoInfo: PhotoInfo, _ completionHandler: @escaping (_ error: Error?, _ url: URL?)-> Void) {
        let photoUrlString = "https://farm\(photoInfo.farm).staticflickr.com/\(photoInfo.server)/\(photoInfo.id)_\(photoInfo.secret).jpg"
        let photoUrl = URL(string: photoUrlString)
        completionHandler(nil, photoUrl)
    }
}
