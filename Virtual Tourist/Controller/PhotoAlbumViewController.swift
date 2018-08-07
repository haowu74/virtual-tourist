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

    // MARK: IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var albumView: UICollectionView!
    @IBOutlet weak var NewCollectionButton: UIButton!
    
    // MARK: IBAction
    
    @IBAction func NewCollection(_ sender: Any) {
        photoInfos.removeAll()
        photoUrls.removeAll()
        images.removeAll()
        NewCollectionButton.isEnabled = false
        getPhotos(lat: (lat?.description)!, lon: (lon?.description)!, radius: photoGeoRadius)
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupFetchedResultsController()
        showMap()
        let count = photosFetchedResultsController.fetchedObjects!.filter{$0.image != nil}.count
        if count > 0 {
            for photo in photosFetchedResultsController.fetchedObjects! {
                if let img = photo.image, let url = photo.photoUrl {
                    images.append(UIImage(data: img)!)
                    photoUrls.append(URL(string: url)!)
                }
            }
        } else {
            NewCollectionButton.isEnabled = false
            getPhotos(lat: (lat?.description)!, lon: (lon?.description)!, radius: photoGeoRadius)
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
    
    // MARK: Properties
    
    var lat: Decimal?
    var lon: Decimal?
    var photoInfos: [PhotoInfo] = []
    var photoUrls: [URL] = []
    var images: [UIImage] = []
    let span = MKCoordinateSpanMake(0.5, 0.5)
    let photoPerDisplay = 21
    let photoGeoRadius = 20
    var photosFetchedResultsController:NSFetchedResultsController<Photo>!
    var dataController:DataController!
    var loadedCells: Int = 0

    // MARK: Core Data function
    
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
    

    // Private functions
    // Get photos info from Flickr API
    private func getPhotos(lat: String, lon: String, radius: Int) {
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
    
    //Display map zooming to the selected annotation
    private func showMap() {
        let cord = CLLocationCoordinate2D.init(latitude: Double(truncating: lat! as NSNumber), longitude: Double(truncating: lon! as NSNumber))
        let region = MKCoordinateRegionMake(cord, span)
        mapView.setCenter(cord, animated: true)
        mapView.setRegion(region, animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate.longitude = Double(truncating: lon! as NSNumber)
        annotation.coordinate.latitude = Double(truncating: lat! as NSNumber)
        mapView.addAnnotation(annotation)
    }
    
    //Get Photos' url from Flickr API
    private func getPhotoUrls() {
        for photoInfo in photoInfos {
            FlickrClient.shared.GetPhotoUrl(photoInfo) { (error, url) in
                if error != nil {
                    print("Error getting photo url.")
                } else if url == nil {
                    print("Error getting photo url.")
                } else {
                    self.photoUrls.append(url!)
                    self.getPhoto(url!)
                }
            }
        }
        performUIUpdatesOnMain {
            self.albumView.reloadData()
        }
    }
    
    //Save photos to Core Data
    private func savePhotos() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", lat! as NSDecimalNumber, lon! as NSDecimalNumber)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try dataController.viewContext.execute(deleteRequest)
        } catch {
            // TODO: handle the error
        }
        var i = 0
        for image in images {

            let photo = Photo(context: dataController.viewContext)
            photo.latitude = lat! as NSDecimalNumber
            photo.longitude = lon! as NSDecimalNumber
            photo.photoUrl = photoUrls[i].absoluteString
            guard let imageData = UIImageJPEGRepresentation(image, 1) else {
                // handle failed conversion
                print("jpg error")
                return
            }
            photo.image = imageData
            photo.id = Int16(i)
            do {
                try dataController.viewContext.save()
            } catch {
                print("Photo Core data save failed")
            }
            i += 1
        }

    }
    
    //Get photo from photo's URL
    private func getPhoto(_ url: URL) {
        let session = URLSession.shared
        var image: UIImage?
        let task = session.dataTask(with: url) { data, response, error in
            if data != nil && error == nil {
                image = UIImage(data: data!)
                self.images.append(image!)
                performUIUpdatesOnMain {
                    self.albumView.reloadData()
                    self.loadedCells += 1
                    if self.loadedCells == self.photoUrls.count {
                        self.NewCollectionButton.isEnabled = true
                    }
                }
            }
        }
        task.resume()
    }
}

// MARK: UICollectionViewDelegate, UICollectionViewDataSource

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumViewCell", for: indexPath) as! PhotoAlbumViewCell
        if self.images.count > indexPath[1] {
            cell.photoInCell.image = self.images[indexPath[1]]
        } else {
            cell.photoInCell.image = UIImage(named: "Placeholder")
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {        
        let alertController = UIAlertController(title: "Want to delete photo from Album?", message: nil, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Delete Photo", style: .default, handler: {
            (action:UIAlertAction!) -> Void in
            self.photoUrls.remove(at: indexPath[1])
            self.images.remove(at: indexPath[1])
            self.albumView.reloadData()
            
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
