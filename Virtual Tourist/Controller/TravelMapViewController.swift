//
//  TravelMapViewController.swift
//  Virtual Tourist
//
//  Created by Hao Wu on 13/6/18.
//  Copyright © 2018 S&J. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import Foundation

class TravelMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @objc func addAnnotation(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            let point = sender.location(in: mapView)
            let tapPoint = mapView.convert(point, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = tapPoint
            mapView.addAnnotation(annotation)
            addPin(Decimal(tapPoint.latitude), Decimal(tapPoint.longitude))
        }

    }
    
    func addPin(_ lat: Decimal, _ lon: Decimal) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = lat as NSDecimalNumber
        pin.longitude = lon as NSDecimalNumber
        var i = 0
        while i < 10000 {
            i += 1
        }
        do {
            try dataController.viewContext.save()
        } catch {
            print("ee")
        }

    }
    
    var locationManager: CLLocationManager!
    
    var dataController:DataController!
    var selectedLon: Decimal?
    var selectedLat: Decimal?
    
    var pinsFetchedResultsController:NSFetchedResultsController<Pin>!
    
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        pinsFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        pinsFetchedResultsController.delegate = self
        do {
            try pinsFetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
 
        //let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.foundTap(_:)))
        let longTagRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.addAnnotation(_:)))
        
        let lat = UserDefaults.standard.object(forKey: "lat") as? CLLocationDegrees ?? nil
        let lon = UserDefaults.standard.object(forKey: "lon") as? CLLocationDegrees ?? nil
        let span_lat = UserDefaults.standard.object(forKey: "span_lat") as? CLLocationDegrees ?? nil
        let span_lon = UserDefaults.standard.object(forKey: "span_lon") as? CLLocationDegrees ?? nil
        var center: CLLocationCoordinate2D? = nil
        var span: MKCoordinateSpan? = nil
        var region: MKCoordinateRegion? = nil
        if let lat = lat, let lon = lon {
            center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        if let span_lat = span_lat, let span_lon = span_lon {
            span = MKCoordinateSpan(latitudeDelta: span_lat, longitudeDelta: span_lon)
        }
        if let center = center, let span = span {
            region = MKCoordinateRegion(center: center, span: span)
        }
        
        longTagRecognizer.delegate = self
        mapView.addGestureRecognizer(longTagRecognizer)
        
        mapView.delegate = self
        if let r = region {
            mapView.setRegion(r, animated: true)
        }
        
        setupFetchedResultsController()
        var annotations: [MKPointAnnotation] = []
        
        for pin in pinsFetchedResultsController.fetchedObjects! {
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = pin.latitude as! CLLocationDegrees
            annotation.coordinate.longitude = pin.longitude as! CLLocationDegrees
            annotations.append(annotation)
        }
        
        mapView.addAnnotations(annotations)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pinsFetchedResultsController = nil
    }
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ToPhotoAlbumViewController" {
            let photoAlbumViewController = segue.destination as! PhotoAlbumViewController
            photoAlbumViewController.lon = selectedLon
            photoAlbumViewController.lat = selectedLat
            photoAlbumViewController.dataController = dataController
        }
    }

}

// MARK: CLLocationManagerDelegate

extension TravelMapViewController {
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as! CLLocation
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.mapView.setRegion(region, animated: true)
    }
}

extension TravelMapViewController {
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        print("Annotation added")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        selectedLat = Decimal(view.annotation?.coordinate.latitude ?? 0)
        selectedLon = Decimal(view.annotation?.coordinate.longitude ?? 0)
        performSegue(withIdentifier: "ToPhotoAlbumViewController", sender: nil)
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("Update")
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        print("finish loading")
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let region = mapView.region
        let lat = region.center.latitude
        let lon = region.center.longitude
        let span_lat = region.span.latitudeDelta
        let span_lon = region.span.longitudeDelta
        UserDefaults.standard.setValue(lat, forKey: "lat")
        UserDefaults.standard.setValue(lon, forKey: "lon")
        UserDefaults.standard.setValue(span_lat, forKey: "span_lat")
        UserDefaults.standard.setValue(span_lon, forKey: "span_lon")
    }
    

}

extension TravelMapViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is MKPinAnnotationView)
    }
    

}



