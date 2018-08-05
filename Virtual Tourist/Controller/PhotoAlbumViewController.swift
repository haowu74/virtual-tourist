//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Hao Wu on 13/6/18.
//  Copyright © 2018 S&J. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var albumView: UICollectionView!
    
    @IBAction func NewCollection(_ sender: Any) {
        photoInfos.removeAll()
        photoUrls.removeAll()
        for i in 0..<images.count {
            images[i] = nil
        }
        GetPhotos(lat: (lat?.description)!, lon: (lon?.description)!, radius: photoGeoRadius)
    }
    
    var lat: Decimal?
    var lon: Decimal?
    var photoInfos: [PhotoInfo] = []
    var photoUrls: [URL] = []
    var images = [UIImage?](repeating: nil, count: 21)
    
    let span = MKCoordinateSpanMake(0.5, 0.5)
    let photoPerDisplay = 21
    let photoGeoRadius = 20
    var photosFetchedResultsController:NSFetchedResultsController<Photo>!
    var dataController:DataController!


    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", lat! as NSDecimalNumber, lon! as NSDecimalNumber)
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        photosFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        photosFetchedResultsController.delegate = self
        do {
            try photosFetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupFetchedResultsController()
        showMap()
        let count = photosFetchedResultsController.fetchedObjects!.filter{$0.image != nil}.count
        if count > 0 {
            for photo in photosFetchedResultsController.fetchedObjects! {
                if let img = photo.image, let url = photo.photoUrl {
                    images.append(UIImage(data: img))
                    photoUrls.append(URL(string: url)!)
                }
            }
        } else {
            GetPhotos(lat: (lat?.description)!, lon: (lon?.description)!, radius: photoGeoRadius)
        }
        
        albumView.delegate = self
        albumView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        savePhotos()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func GetPhotos(lat: String, lon: String, radius: Int) {
        FlickrClient.shared.GetPhotosFromGeo(lat, lon, radius) {(error, infos) in
            if error != nil {
                
            } else if infos.count == 0 {
                
            } else {
                //get photo ids successfully
                if infos.count <= self.photoPerDisplay {
                    self.photoInfos = infos
                } else {
                    var photos = infos
                    for _ in (0..<self.photoPerDisplay) {
                        let randPick = Int(arc4random_uniform(UInt32(photos.count)))
                        self.photoInfos.append(photos[randPick])
                        photos.remove(at: randPick)
                    }
                }
                self.getPhotoUrls()
            }
        }
        
    }
    
    func showMap() {
        let cord = CLLocationCoordinate2D.init(latitude: Double(truncating: lat! as NSNumber), longitude: Double(truncating: lon! as NSNumber))
        let region = MKCoordinateRegionMake(cord, span)
        mapView.setCenter(cord, animated: true)
        mapView.setRegion(region, animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate.longitude = Double(truncating: lon! as NSNumber)
        annotation.coordinate.latitude = Double(truncating: lat! as NSNumber)
        mapView.addAnnotation(annotation)
    }
    
    func getPhotoUrls() {
        for photoInfo in photoInfos {
            FlickrClient.shared.GetPhotoUrl(photoInfo) { (error, url) in
                if error != nil {
                    
                } else if url == nil {
                    
                } else {
                    self.photoUrls.append(url!)
                }
            }
        }
        performUIUpdatesOnMain {
            self.albumView.reloadData()
        }
    }
    
    func showPhotos() {
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func savePhotos() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", lat! as NSDecimalNumber, lon! as NSDecimalNumber)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try dataController.viewContext.execute(deleteRequest)
        } catch {
            // TODO: handle the error
        }
        
        for i in 0..<21 {
            if images[i] == nil {
                break
            }
            let photo = Photo(context: dataController.viewContext)
            photo.latitude = lat! as NSDecimalNumber
            photo.longitude = lon! as NSDecimalNumber
            photo.photoUrl = photoUrls[i].absoluteString
            guard let imageData = UIImageJPEGRepresentation(images[i]!, 1) else {
                // handle failed conversion
                print("jpg error")
                return
            }
            photo.image = imageData
            photo.id = Int16(i)
            do {
                try dataController.viewContext.save()
            } catch {
                print("ee")
            }
        }

    }
    
    func showPhoto(_ url: URL, _ completionHandler: @escaping (_ error: Error?, _ image: UIImage) -> Void) {
        let session = URLSession.shared
        var image: UIImage?
        let task = session.dataTask(with: url) { data, response, error in
            if data != nil && error == nil {
                image = UIImage(data: data!)
            }
            performUIUpdatesOnMain {
                completionHandler(nil, image!)
            }
        }
        task.resume()
    }

}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumViewCell", for: indexPath) as! PhotoAlbumViewCell
        if images[indexPath[1]] != nil {
            cell.photoInCell.image = self.images[indexPath[1]]
        } else {
            if photoUrls.count > 0 && indexPath[1] < photoUrls.count {
                showPhoto(photoUrls[indexPath[1]]) {error, image in
                    cell.photoInCell.image = image
                    self.images[indexPath[1]] = image
                }
            }
        }
        return cell
    }
}
